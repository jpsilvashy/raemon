require 'spec_helper'

describe Raemon::Configuration do
  describe '#[]' do
    let(:name) { 'Cheese Burgers' }

    it 'retrieves the value of the attribute' do
      described_class.name = name
      described_class[:name].should == name
    end

    it 'returns nil for an invalid attribute name' do
      described_class[:splat].should be_nil
    end
  end
end
