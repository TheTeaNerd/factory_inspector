require 'spec_helper'

require 'factory_inspector/report'

describe FactoryInspector::Report do

  let(:foo) { 'FooFactory' }

  context 'when constructed' do
    before :all do
      @report = FactoryInspector::Report.new(factory_name: :foo)
    end

    it 'should be named for the factory' do
      expect(@report.factory_name).to eq(:foo)
    end

    it 'should have recorded zero calls' do
      expect(@report.number_of_calls).to eq(0)
    end
  end
end
