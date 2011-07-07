module Raemon
  class Util
    # Creates and returns a new File object.  The File is unlinked
    # immediately, switched to binary mode, and userspace output
    # buffering is disabled. Method pulled from Unicorn library.
    def self.tmpio
      tmp_path = File.join(Dir.tmpdir, rand.to_s)

      begin
        fp = File.open(tmp_path, File::RDWR | File::CREAT | File::EXCL, 0600)
      rescue Errno::EEXIST
        retry
      end

      File.unlink(fp.path)

      fp.binmode

      fp.sync = true

      fp
    end
  end
end
