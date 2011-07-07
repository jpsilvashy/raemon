require 'spec_helper'

describe Raemon::Server do
  its(:config) { should == Raemon::Configuration }
end
