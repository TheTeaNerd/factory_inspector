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
                :total_time,
                :factory_calls
    attr_accessor :factories_called

    def initialize(factory_name:)
      @factory_name = factory_name
      @factory_calls = []
      @factories_called = []
    end

    def all_calls
      calls_by_count.reduce('') do |memo, (call, count)|
        memo += "%5s call(s):#{call}\n" % count
        memo
      end
    end

    def time_per_call
      (number_of_calls == 0) ? 0 : (total_time.to_f / number_of_calls.to_f)
    end

    # Update this report with a new factory call
    # * [time] The time taken, in seconds, to call the factory
    # * [strategy] The strategy used by the factory
    def update(time:, strategy:, call_stack:)
      @factory_calls << FactoryCall.new(factory: @factory_name,
                                        stack: call_stack,
                                        strategy: strategy,
                                        time: time)
    end

    def number_of_calls
      @factory_calls.size
    end

    def total_time
      @total_time ||= @factory_calls.sum(&:time)
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

      calls = other.factory_calls.reduce([]) do |memo, other_factory_call|

        matching_calls = @factory_calls.select do |previous_factory_call|
          previous_factory_call.called_by? other_factory_call
        end

        if matching_calls.any?
          memo << Hashr.new(called: matching_calls, caller: other_factory_call)
        end
        memo
      end

      calls.any? ? calls : false
    end

    private

    def worst_time
      @worst_time ||= @factory_calls.max_by(&:time).time
    end

    def strategies
      @factory_calls.map(&:strategy).uniq
    end

    def calls_by_count
      factory_calls.map(&:stack)
        .map { |stack| stack.join(' <- ').gsub(/\A/, '    ') }
        .each_with_object(Hash.new(0)) { |call, counts| counts[call] += 1 }
        .sort_by { |_call, count| count }
        .reverse
    end
  end
end
