module FactoryInspector
  # Report on how a FactoryGirl Factory was used in a test run.
  # Holds simple metrics and can be updated with new calls.
  #
  # All times are in seconds.
  class Report
    include Comparable

    attr_reader :factory_name,
                :calls,
                :worst_time,
                :total_time,
                :strategies,
                :callers

    def initialize(factory_name: 'unknown')
      @factory_name = factory_name
      @calls = 0
      @worst_time = 0
      @total_time = 0
      @strategies = Set.new
      @callers = []
    end

    def all_calls
      callers.map do |stack|
        stack.join(' -> ').gsub(/\A/, '    ')
      end.join("\n") + "\n"
    end

    def time_per_call
      (@calls == 0) ? 0 : (@total_time.to_f / @calls.to_f)
    end

    # Update this report with a new factory call
    # * [time] The time taken, in seconds, to call the factory
    # * [strategy] The strategy used by the factory
    def update(time: 0, strategy: '', call_stack: [])
      @calls += 1
      record_time(time: time)
      @strategies << strategy.to_s
      @callers << call_stack
    end

    def self.sort_description
      'total time'
    end

    def <=>(other)
      total_time <=> other.total_time
    end

    def to_s
      format("  %-30.30s % 5.0d    %8.4f    %5.5f  %5.4f      %s\n",
             factory_name,
             calls,
             total_time,
             time_per_call,
             worst_time,
             strategies.to_a.join(', '))
    end

    private

    def record_time(time: 0)
      @worst_time = time if time > @worst_time
      @total_time += time
    end
  end
end
