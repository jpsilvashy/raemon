require 'spec_helper'

describe Raemon::Configuration do
  describe '#option' do
    before(:all) do
      described_class.option(:test_setting, :default => true)
    end

    it "creates a getter for an option" do
      described_class.should respond_to(:test_setting)
    end

    it "creates a setter for the option" do
      described_class.should respond_to(:test_setting=)
    end

    it "creates a conditional for the option" do
      described_class.should respond_to(:test_setting?)
    end

    it "allows the setting of a default value" do
      described_class.test_setting.should == true
    end
  end

  its(:server_name) { should == described_class::DEFAULT_SERVER_NAME }

  its(:detach) { should == described_class::DEFAULT_DETACH }

  its(:num_workers) { should == described_class::DEFAULT_NUM_WORKERS }

  its(:log_level) { should == described_class::DEFAULT_LOG_LEVEL }

  its(:worker_class) { should be_nil }

  its(:timeout) { should == described_class::DEFAULT_TIMEOUT }

  its(:env) { should == described_class::DEFAULT_ENVIRONMENT }

  its(:memory_limit) { should == described_class::DEFAULT_MEMORY_LIMIT_IN_MEGABYTES }

  describe '.logger' do
    before(:each) do
      described_class.logger = nil
    end

    it 'is a logger' do
      described_class.logger.should be_a(Logger)
    end

    it 'sets the logger to use the desired log level' do
      described_class.log_level = :warn
      described_class.logger.level.should == Logger::WARN
    end
  end

  describe '.logger=' do
    let(:fake_logger) { double }

    it 'sets the logger' do
      described_class.logger = fake_logger
      described_class.logger.should == fake_logger
    end
  end

  describe '.root=' do
    it 'sets the root location of the project' do
      described_class.root = '.'
      described_class.root.to_s.should == File.expand_path('.')
    end
  end

  describe '.root' do
    it 'is a Pathname' do
      described_class.root.should be_a(Pathname)
    end

    it 'raises an exception when not set' do
      expect {
        described_class.root = nil
        described_class.root
      }.to raise_error(StandardError, 'Raemon::Config.root must be set')
    end
  end
end
