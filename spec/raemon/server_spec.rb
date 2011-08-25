require 'spec_helper'

describe Raemon::Server do
  describe '.boot!' do
    before(:each) do
      subject.stub(:load_environment)
      subject.stub(:load_initializers)
      subject.stub(:load_lib)
      subject.stub(:initialize_logger)
    end

    it 'loads the environment configuration' do
      subject.should_receive(:load_environment)
      subject.boot!
    end

    it 'loads any initializers' do
      subject.should_receive(:load_initializers)
      subject.boot!
    end

    it 'loads library files' do
      subject.should_receive(:load_lib)
      subject.boot!
    end
  end

  describe '.startup!' do
    before(:all) do
      # Stupid config to silence some aspects we don't care about
      Raemon.config do |c|
        c.worker_class = 'String'
      end
    end

    before(:each) do
      Raemon::Master.stub(:start)
    end

    it 'starts the master daemon' do
      Raemon::Master.should_receive(:start)
      subject.startup!
    end

    it 'stops the script if the master daemon is already running' do
      subject.stub(:running?) { true }
      subject.should_receive(:exit)
      subject.startup!
    end
  end
end
