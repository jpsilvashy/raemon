require 'spec_helper'

describe Raemon do
  its(:logger) { should == Raemon::Configuration.logger }

  describe '.config' do
    it 'yields the configuration object' do
      described_class.config do |config|
        config.should == Raemon::Configuration
      end
    end

    it 'returns the configuration object' do
      described_class.config.should == Raemon::Configuration
    end
  end
end
