require 'factory_inspector/factory_call'

module FactoryInspector
  # Report on how a FactoryGirl Factory was used in a test run.
  # Holds simple metrics and can be updated with new calls.
  #
  # All times are in seconds.
  class Report
    include Comparable

    attr_reader :factory_name,
                :number_of_calls,
                :worst_time,
                :total_time,
                :strategies,
                :calls
    attr_accessor :factories_called

    def initialize(factory_name: 'unknown')
      @factory_name = factory_name
      @number_of_calls = 0
      @worst_time = 0
      @total_time = 0
      @strategies = []
      @calls = []
      @factories_called = []
    end

    def all_calls
      calls_by_count.reduce('') do |memo, (call, count)|
        memo += "%5s call(s):#{call}\n" % count
        memo
      end
    end

    def time_per_call
      (@number_of_calls == 0) ? 0 : (@total_time.to_f / @number_of_calls.to_f)
    end

    # Update this report with a new factory call
    # * [time] The time taken, in seconds, to call the factory
    # * [strategy] The strategy used by the factory
    def update(time: 0, strategy: '', call_stack: [])
      @number_of_calls += 1
      record_time(time: time)
      @strategies << strategy.to_s
      @calls << FactoryInspector::FactoryCall.new(factory: factory_name,
                                                  stack: call_stack,
                                                  strategy: strategy)
    end

    def self.sort_description
      'total time'
    end

    def <=>(other)
      total_time <=> other.total_time
    end

    def to_s
      format("  %-30.30s % 5.0d  %8.4f   %5.5f    %5.4f  %s\n",
             factory_name,
             number_of_calls,
             total_time,
             time_per_call,
             worst_time,
             strategies.uniq.join(', '))
    end

    def called_by?(other)
      return false if other == self

      result = other.calls.reduce([]) do |memo, other_call_stack|
        match = callers_include?(other_call_stack)
        if match
          memo << Hashr.new(called: match, caller: other_call_stack)
        end
        memo
      end
      result.any? ? result : false
    end

    private

    def callers_include?(factory_call)
      matches = @calls.select do |previous_call|
        ((factory_call.stack & previous_call.stack).size == factory_call.stack.size)
      end
      matches.any? ? matches : false
    end

    def record_time(time: 0)
      @worst_time = time if time > @worst_time
      @total_time += time
    end

    def calls_by_count
      calls.map(&:stack)
        .map { |stack| stack.join(' <- ').gsub(/\A/, '    ') }
        .each_with_object(Hash.new(0)) { |call, counts| counts[call] += 1 }
        .sort_by { |_call, count| count }
        .reverse
    end
  end
end
