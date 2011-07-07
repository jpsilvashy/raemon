require 'spec_helper'

describe Raemon::Server do
  its(:config) { should == Raemon::Configuration }

  its(:server_name) { should == Raemon::Configuration.name }

  describe '.server_name_key' do
    let(:server_name) { 'My Server' }

    before(:each) do
      described_class.stub(:server_name) { server_name }
    end

    it 'is the downcase name of the server' do
      described_class.server_name_key.should =~ /[a-z]/
    end

    it 'underscores spaces in the server name' do
      described_class.server_name_key.should == 'my_server'
    end
  end

  describe '.worker_class' do
    it 'is the class to use as a worker' do
      described_class.config.worker_class = "String"
      described_class.worker_class.should == String
    end
  end
end
