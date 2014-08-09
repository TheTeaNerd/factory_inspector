module FactoryInspector
  # Report on how a FactoryGirl Factory was used in a test run.
  # Holds simple metrics and can be updated with new calls.
  class Report
    include Comparable

    attr_reader :factory_name,
                :calls,
                :worst_time_in_seconds,
                :total_time_in_seconds,
                :strategies

    def initialize(factory_name: 'unknown')
      @factory_name = factory_name
      @calls = 0
      @worst_time_in_seconds = 0
      @total_time_in_seconds = 0
      @strategies = Set.new
    end

    def time_per_call_in_seconds
      (@calls == 0) ? 0 : (@total_time_in_seconds.to_f / @calls.to_f)
    end

    # Update this report with a new factory call
    # * [time] The time taken, in seconds, to call the factory
    # * [strategy] The strategy used by the factory
    def update(time: 0, strategy: '')
      @calls += 1
      record_time(time: time)
      @strategies << strategy.to_s
    end

    def <=>(other)
      time_per_call_in_seconds <=> other.time_per_call_in_seconds
    end

    def to_s
      format("  %-30.30s % 5.0d    %8.4f    %5.5f  %5.4f      %s\n",
             factory_name,
             calls,
             total_time_in_seconds,
             time_per_call_in_seconds,
             worst_time_in_seconds,
             strategies.to_a.join(', '))
    end

    private

    def record_time(time: 0)
      if time > @worst_time_in_seconds
        @worst_time_in_seconds = time
      end
      @total_time_in_seconds += time
    end
  end
end
