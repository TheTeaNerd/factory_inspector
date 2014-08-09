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
      expect(@report.calls).to eq(0)
    end

    it 'should have a zero worst time' do
      expect(@report.worst_time_in_seconds).to eq(0)
    end

    it 'should have a zero total time' do
      expect(@report.total_time_in_seconds).to eq(0)
    end

    it 'should have recorded no strategies' do
      expect(@report.strategies).to be_empty
    end

    it 'should have a zero time-per-call' do
      expect(@report.time_per_call_in_seconds).to eq(0)
    end
  end

  context 'when updated' do
    before :all do
      @report = FactoryInspector::Report.new(factory_name: :foo)
      @report.update(time: 3, strategy: :build)
      @report.update(time: 5, strategy: 'create')
    end

    it 'should have incremented the call count' do
      expect(@report.calls).to eq(2)
    end

    it 'should have recorded the total time' do
      expect(@report.total_time_in_seconds).to eq(8)
    end

    it 'should report the time per call' do
      expect(@report.time_per_call_in_seconds).to eq(4)
    end

    it 'should report the strategies used' do
      expect(@report.strategies).to include('build')
      expect(@report.strategies).to include('create')
    end
  end

  describe '#to_s, #comparable' do
    before :all do
      @good = FactoryInspector::Report.new(factory_name: :good)
      @good.update(time: 0.003, strategy: :build)
      @good.update(time: 0.003, strategy: :build)
      @good.update(time: 0.001, strategy: :build)
      @good.update(time: 0.002, strategy: :build)

      @bad = FactoryInspector::Report.new(factory_name: :bad)
      @bad.update(time: 1, strategy: :create)
      @bad.update(time: 2, strategy: :create)
      @bad.update(time: 3, strategy: :create)
      @bad.update(time: 4, strategy: :create)
    end

    it 'should pretty print a slow factory correctly' do
      expect(@bad.to_s).to match '  bad                                4     10.0000    2.50000  4.0000      create'
    end

    it 'should pretty print a good factory correctly' do
      expect(@good.to_s).to match '  good                               4      0.0090    0.00225  0.0030      build'
    end

    describe '#comparable' do
      it 'fast factory < slow factory' do
        expect(@good < @bad).to be true
      end

      it 'fast factory > slow factory' do
        expect(@good > @bad).to be false
      end
    end
  end

end
