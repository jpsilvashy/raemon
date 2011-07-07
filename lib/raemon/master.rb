module Raemon
  class Master
    WORKERS = {}

    SELF_PIPE = []

    SIG_QUEUE = []

    CHUNK_SIZE = (16*1024)

    # list of signals we care about and trap in master.
    QUEUE_SIGS = [ :WINCH, :QUIT, :INT, :TERM, :USR1, :USR2, :HUP, :TTIN, :TTOU ]

    attr_accessor :name, :num_workers, :worker_class,
                  :master_pid, :pid_file,
                  :logger, :timeout, :memory_limit

    def self.start(num_workers, worker_class, options={})
      master = new(options)
      master.start(num_workers, worker_class)
    end

    def self.stop(options={})
      pid_file = options[:pid_file]
      pid = options[:pid] || (File.read(pid_file).to_i rescue 0)
      Process.kill('QUIT', pid) if pid > 0
    rescue Errno::ESRCH
    end

    def initialize(options={})
      @detach         = options[:detach] || false
      @name           = options[:name] || 'Raemon'
      @pid_file       = options[:pid_file]
      @logger         = options[:logger] || Logger.new(STDOUT)
      @timeout        = options[:timeout] || 180 # 3 minutes
      @memory_limit   = options[:memory_limit] # in MB

      daemonize if @detach
    end

    def start(num_workers, worker_class)
      logger.info "=> Starting #{name} with #{num_workers} worker(s)"

      @master_pid   = Process.pid
      @num_workers  = num_workers
      @worker_class = worker_class

      # Check if the worker implements our interface
      if !worker_class.include?(Raemon::Worker)
        logger.error "** Invalid Raemon worker"
        logger.close
        exit
      end

      # Start the master loop which spawns and monitors workers
      master_loop!
    end

    # Terminates all workers, but does not exit master process
    def stop(graceful=true)
      kill_each_worker(graceful ? :QUIT : :TERM)
      timeleft = timeout
      step = 0.2
      reap_all_workers
      until WORKERS.empty?
        sleep(step)
        reap_all_workers
        (timeleft -= step) > 0 and next
        kill_each_worker(:KILL)
      end
    end

    def worker_heartbeat!(worker)
      return if timeout <= 0
      @last_pulse ||= 0

      begin
        if Time.now.to_i > @last_pulse + (timeout/2)
          # Pulse (our lifeline to the master process)
          @last_pulse = Time.now.to_i
          @p = 0 == @p ? 1 : 0
          worker.pulse.chmod(@p)

          # Make sure master is still around otherwise exit
          master_pid == Process.ppid or return
        end
      rescue => ex
        if worker.pulse
          logger.error "Unhandled listen loop exception #{ex.inspect}."
          logger.error ex.backtrace.join("\n")
        end
      end
    end

    private

      # monitors children and receives signals forever
      # (or until a termination signal is sent).  This handles signals
      # one-at-a-time time and we'll happily drop signals in case somebody
      # is signalling us too often.
      def master_loop!
        # this pipe is used to wake us up from select(2) in #join when signals
        # are trapped.  See trap_deferred
        init_self_pipe!
        respawn = true

        QUEUE_SIGS.each { |sig| trap_deferred(sig) }
        trap(:CHLD) { |sig_nr| awaken_master }

        process_name 'master'
        logger.info "master process ready"

        # Spawn workers for the first time
        maintain_worker_count

        begin
          loop do
            monitor_memory_usage
            reap_all_workers

            case SIG_QUEUE.shift
            when nil
              murder_lazy_workers
              maintain_worker_count if respawn
              master_sleep
            when :QUIT # graceful shutdown
              break
            when :TERM, :INT # immediate shutdown
              stop(false)
              break
            when :USR1
              kill_each_worker(:USR1)
            when :USR2
              kill_each_worker(:USR2)
            when :WINCH
              if Process.ppid == 1 || Process.getpgrp != $$
                respawn = false
                logger.info "gracefully stopping all workers"
                kill_each_worker(:QUIT)
              else
                logger.info "SIGWINCH ignored because we're not daemonized"
              end
            when :TTIN
              @num_workers += 1
            when :TTOU
              @num_workers -= 1 if @num_workers > 0
            when :HUP
              # TODO: should restart the workers, but a :QUIT could stall
              # respawn = true
              # kill_each_worker(:QUIT)
            end
          end
        rescue Errno::EINTR
          retry
        rescue => ex
          logger.error "Unhandled master loop exception #{ex.inspect}."
          logger.error ex.backtrace.join("\n")
          retry
        end

        # Gracefully shutdown all workers on our way out
        stop
        logger.info "master complete"

        # Close resources
        unlink_pid_safe(pid_file) if pid_file
        logger.close
      end


      # defer a signal for later processing in #master_loop! (master process)
      def trap_deferred(signal)
        trap(signal) do |sig_nr|
          if SIG_QUEUE.size < 5
            SIG_QUEUE << signal
            awaken_master
          else
            logger.error "ignoring SIG#{signal}, queue=#{SIG_QUEUE.inspect}"
          end
        end
      end

      # wait for a signal handler to wake us up and then consume the pipe
      # Wake up every second anyways to run murder_lazy_workers
      def master_sleep
        begin
          ready = IO.select([SELF_PIPE.first], nil, nil, 1) or return
          ready.first && ready.first.first or return
          loop { SELF_PIPE.first.read_nonblock(CHUNK_SIZE) }
        rescue Errno::EAGAIN, Errno::EINTR
        end
      end

      def awaken_master
        begin
          SELF_PIPE.last.write_nonblock('.') # wakeup master process from select
        rescue Errno::EAGAIN, Errno::EINTR
          # pipe is full, master should wake up anyways
          retry
        end
      end

      # reaps all unreaped workers
      def reap_all_workers
        begin
          loop do
            wpid, status = Process.waitpid2(-1, Process::WNOHANG)
            wpid or break
            worker = WORKERS.delete(wpid) and worker.pulse.close rescue nil
            logger.info "reaped #{status.inspect} " \
                        "worker=#{worker.id rescue 'unknown'}"
          end
        rescue Errno::ECHILD
        end
      end

      # forcibly terminate all workers that haven't checked-in in timeout
      # seconds.  The timeout is implemented using an unlinked File
      # shared between the parent process and each worker.  The worker
      # runs File#chmod to modify the ctime of the File.  If the ctime
      # is stale for >timeout seconds, then we'll kill the corresponding
      # worker.
      def murder_lazy_workers
        return if timeout <= 0

        diff = stat = nil

        WORKERS.dup.each_pair do |wpid, worker|
          begin
            stat = worker.pulse.stat
          rescue => ex
            logger.warn "worker=#{worker.id} PID:#{wpid} stat error: #{ex.inspect}"
            kill_worker(:QUIT, wpid)
            next
          end
          stat.mode == 0100000 and next
          (diff = (Time.now - stat.ctime)) <= timeout and next
          logger.error "worker=#{worker.id} PID:#{wpid} timeout " \
                       "(#{diff}s > #{timeout}s), killing"
          kill_worker(:KILL, wpid) # take no prisoners for timeout violations
        end
      end

      # Spawn workers, and initalize new workers if some are no longer running
      def spawn_workers
        (0...num_workers).each do |id|
          WORKERS.values.include?(id) and next
          worker = worker_class.new(self, id, Raemon::Util.tmpio)

          # Fork the worker processes wrapped in the worker loop
          WORKERS[fork { worker_loop!(worker) }] = worker
        end
      end

      def maintain_worker_count
        off = num_workers - WORKERS.size

        if off.zero?
          return
        elsif off == num_workers
          # None of the workers are running, lets be gentle
          @spawn_attempts ||= 0
          sleep 1 if @spawn_attempts > 1
          if timeout > 0 && @spawn_attempts > timeout
            # We couldn't get the workers going after timeout
            # seconds, so let's assume this will never work
            logger.error "Unable to spawn workers after #{@spawn_attempts} attempts"
            master_quit
            return
          end
          @spawn_attempts += 1
        else
          @spawn_attempts = nil
        end

        return spawn_workers if off > 0

        WORKERS.dup.each_pair do |wpid, worker|
          worker.id >= num_workers && kill_worker(:QUIT, wpid) rescue nil
        end
      end

      # gets rid of stuff the worker has no business keeping track of
      # to free some resources and drops all sig handlers.
      # traps for USR1, USR2, and HUP may be set in the after_fork Proc
      # by the user.
      def init_worker_process(worker)
        QUEUE_SIGS.each { |sig| trap(sig, nil) }
        trap(:CHLD, 'DEFAULT')
        SIG_QUEUE.clear
        process_name "worker[#{worker.id}]"

        init_self_pipe!
        WORKERS.values.each { |other_worker| other_worker.pulse.close rescue nil }
        WORKERS.clear

        worker.pulse.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
        @timeout /= 2.0 # halve it for select
      end

      # runs inside each forked worker, this sits around and waits
      # for connections and doesn't die until the parent dies (or is
      # given a INT, QUIT, or TERM signal)
      def worker_loop!(worker)
        init_worker_process(worker)

        # Graceful shutdown
        trap(:QUIT) do
          worker.stop if worker.respond_to?(:stop)
          exit!(0)
        end

        # Immediate termination
        [:TERM, :INT].each { |sig| trap(sig) { exit!(0) } }

        # Worker start
        logger.info "worker=#{worker.id} ready"
        worker.start if worker.respond_to?(:start)

        # Worker run loop
        worker.run
      end

      # delivers a signal to a worker and fails gracefully if the worker
      # is no longer running.
      def kill_worker(signal, wpid)
        begin
          Process.kill(signal, wpid)
        rescue Errno::ESRCH
          worker = WORKERS.delete(wpid) and worker.pulse.close rescue nil
        end
      end

      # delivers a signal to each worker
      def kill_each_worker(signal)
        WORKERS.keys.each { |wpid| kill_worker(signal, wpid) }
      end

      # Make the master quit
      def master_quit
        SIG_QUEUE << :QUIT
      end

      # unlinks a PID file at given +path+ if it contains the current PID
      # still potentially racy without locking the directory (which is
      # non-portable and may interact badly with other programs), but the
      # window for hitting the race condition is small
      def unlink_pid_safe(path)
        (File.read(path).to_i == $$ and File.unlink(path)) rescue nil
      end

      # returns a PID if a given path contains a non-stale PID file,
      # nil otherwise.
      def valid_pid?(path)
        wpid = File.read(path).to_i
        wpid <= 0 and return
        begin
          Process.kill(0, wpid) # send null signal to check if its alive
          return wpid
        rescue Errno::ESRCH
          # don't unlink stale pid files, racy without non-portable locking...
        end
        rescue Errno::ENOENT
      end

      def process_name(tag)
        $0 = "#{name} #{tag}"
      end

      def init_self_pipe!
        SELF_PIPE.each { |io| io.close rescue nil }
        SELF_PIPE.replace(IO.pipe)
        SELF_PIPE.each { |io| io.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC) }
      end

      def daemonize
        exit if Process.fork

        Process.setsid

        Dir.chdir '/'
        File.umask 0000

        STDIN.reopen '/dev/null'
        STDOUT.reopen '/dev/null', 'a'
        STDERR.reopen '/dev/null', 'a'

        File.open(pid_file, 'w') { |f| f.puts(Process.pid) } if pid_file
      end

      # Check memory usage every 60 seconds if a memory limit is enforced
      def monitor_memory_usage
        return if memory_limit.nil?
        @last_memory_chk ||= 0

        if @last_memory_chk + 60 < Time.now.to_i
          @last_memory_chk = Time.now.to_i
          WORKERS.dup.each_pair do |wpid, worker|
            if memory_usage(wpid) > (memory_limit*1024)
              logger.warn "memory limit (#{memory_limit}MB) reached by worker=#{worker.id}"
              kill_worker(:QUIT, wpid)
            end
          end
        end
      end

      def memory_usage(pid)
        `ps -o rss= -p #{pid}`.to_i
      end
  end
end
