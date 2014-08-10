require 'active_support/notifications'
require 'factory_inspector/report'
require 'factory_inspector/configuration'
require 'term/ansicolor'
require 'chronic_duration'

module FactoryInspector
  # Inspects the Factory via the callback `analyze`
  class Inspector
    include Term::ANSIColor

    def initialize
      @here = Dir.getwd
      @reports = {}
      instrument_factory_girl
    end

    def generate_summary
      return if @reports.empty?

      puts
      puts bold + header + clear
      sorted_reports.take(summary_size).each { |_, report| puts report }
    end

    def generate_report(filename: Configuration.default_report_path)
      return if @reports.empty?

      file = File.open(filename, 'w')
      file.write header
      sorted_reports.each do |name, report|
        file.write report
      end
      file.write("\n\nComplete caller information for each factory:\n")
      sorted_reports.each do |name, report|
        file.write "\nFACTORY: '#{name}' " \
                   "(called #{report.callers.size} times)\n"
        file.write report.all_calls
      end
      file.close

      relative_filename = filename.gsub(/#{@here}/, '.')
      puts "\nFull report in '#{cyan + relative_filename + clear}'"
    end

    # Callback for use by ActiveSupport::Notifications.
    # Has to be public for ActiveSupport to use it.
    #
    # * [factory_name] Factory name
    # * [start_time] The start time of the factory call (seconds)
    # * [finish_time] The finish time of the factory call (seconds)
    # * [strategy] The strategy used when calling the factory
    #
    def analyze(factory, start, finish, strategy)
      timegc = (finish - start)
      if timegc == 0.0
        warn "A call to #{factory} took zero time, cannot analyze. Is TimeCop is use?"
        return
      end

      call_stack = caller.grep(/#{@here}/).map do |call|
        call.gsub(/\A#{@here}\/(.+)(:\d+):.+\z/, '\1\2')
      end

      @reports[factory] ||= FactoryInspector::Report.new(factory_name: factory)
      @reports[factory].update(time: timegc,
                               strategy: strategy,
                               call_stack: call_stack)
    end

    private

    def summary_size
      5
    end

    def sorted_reports
      @reports.sort.reverse
    end

    def header
      'FACTORY INSPECTOR: ' \
      "#{@reports.values.size} factories used, " \
      "#{total_calls} calls made over #{pretty_total_time}\n\n" \
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

    def pretty_total_time
      ChronicDuration.output(total_time.round(2), keep_zero: true)
    end

    def total_time
      @reports.values.reduce(0) { |total, report| total + report.total_time }
    end

    def total_calls
      @reports.values.reduce(0) { |total, report| total + report.calls }
    end
  end
end
