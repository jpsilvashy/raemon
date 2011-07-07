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

    it 'initializes the logger' do
      subject.should_receive(:initialize_logger)
      subject.boot!
    end
  end
end
