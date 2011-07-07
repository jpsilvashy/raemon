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

  its(:name) { should == described_class::DEFAULT_NAME }

  its(:detatch) { should == described_class::DEFAULT_DETATCH }

  its(:num_workers) { should == described_class::DEFAULT_NUM_WORKERS }

  its(:logger) { should be_a(Logger) }

  its(:worker_class) { should be_nil }

  its(:timeout) { should be_nil }

  its(:memory_limit) { should be_nil }
end
