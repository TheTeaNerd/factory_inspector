require 'active_support/notifications'
require 'factory_inspector/report'
require 'term/ansicolor'

module FactoryInspector
  # Inspects the Factory via the callback `analyze`
  class Inspector
    include Term::ANSIColor

    def initialize
      @reports = {}
      instrument_factory_girl
    end

    def generate_summary
      puts
      puts bold + header + clear
      sorted_reports.take(summary_size).each { |_, report| puts report }
    end

    def generate_report(filename)
      file = File.open(filename, 'w')
      file.write header
      sorted_reports.each { |_, report| file.write report }
      file.close
      puts "\nFull report in '#{cyan + filename + clear}'"
    end

    # Callback for use by ActiveSupport::Notifications, not for end
    # user use directly though it has to be public for ActiveSupport
    # to see it.
    #
    # * [factory_name] Factory name
    # * [start_time] The start time of the factory call (seconds)
    # * [finish_time] The finish time of the factory call (seconds)
    # * [strategy] The strategy used when calling the factory
    #
    def analyze(factory, start, finish, strategy)
      time_in_seconds = (finish - start)
      if time_in_seconds == 0.0
        warn "A call to #{factory} took zero time, cannot analyze. Is TimeCop is use?"
        return
      end
      @reports[factory] ||= FactoryInspector::Report.new(factory_name: factory)
      @reports[factory].update(time: time_in_seconds, strategy: strategy)
    end

    private

    def summary_size
      5
    end

    def sorted_reports
      @reports.sort.reverse
    end

    def header
      "FACTORY INSPECTOR:\n" \
      "  #{@reports.values.size} factories used, " \
      "#{total_calls} calls made over #{total_time.round(2)} seconds\n\n" \
      "  FACTORY NAME                     " \
      "TOTAL  OVERALL   TIME PER  LONGEST   STRATEGIES\n" \
      "                                   " \
      "CALLS  TIME (s)  CALL (s)  CALL (s)\n"
    end

    def instrument_factory_girl
      event = 'factory_girl.run_factory'
      notifications = ActiveSupport::Notifications
      notifications.subscribe(event) do |_, start, finish, _, payload|
        analyze(payload[:name], start, finish, payload[:strategy])
      end
    end

    def total_time
      @reports.values.reduce(0) { |total, report| total + report.total_time_in_seconds }
    end

    def total_calls
      @reports.values.reduce(0) { |total, report| total + report.calls }
    end
  end
end
