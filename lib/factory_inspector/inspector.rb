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
      @warnings = []
    end

    def generate_summary
      return if @reports.empty?

      puts
      puts bold + header + clear
      sorted_reports.take(summary_size).each { |_, report| puts report }
      puts "  (Slowest sorted by #{cyan + sort_description + clear}.)"
    end

    def generate_report(filename: Configuration.default_report_path)
      return if @reports.empty?

      file = File.open(filename, 'w')
      file.write header

      reports = sorted_reports
      reports.each { |_, report| file.write report }

      file.write("\n\nComplete caller information for each factory:\n")
      reports.each do |name, report|
        file.write "\nFACTORY: '#{name}' (#{report.callers.size} calls)\n"
        file.write report.all_calls
      end
      file.close

      print "\nFull report in '#{cyan + relative(filename) + clear}'"
    end

    def generate_warnings_log(filename: Configuration.default_warnings_log_path)
      return if @warnings.empty?

      file = File.open(filename, 'w')
      file.write("Factory Inspector - #{@warnings.size} warnings\n")
      @warnings.each do |warning|
        file.write("  * #{warning[:message]}\n")
        file.write("    * #{printable_call_stack(warning[:call_stack])}\n")
      end
      file.close

      puts "#{@warnings.size} warnings in '#{cyan + relative(filename) + clear}'"
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
      execution_time = (finish - start)
      if execution_time == 0.0
        warning(message:  "A call to '#{factory}' took zero time, cannot analyze timing. " \
                          'Time may be frozen if a Gem like TimeCop is being used?',
                call_stack: call_stack)
      else
        @reports[factory] ||= Report.new(factory_name: factory)
        @reports[factory].update(time: execution_time,
                                 strategy: strategy,
                                 call_stack: call_stack)
      end
    end

    private

    def printable_call_stack(call_stack)
      call_stack.join(' -> ') + "\n"
    end

    def warning(message: '', call_stack: [])
      @warnings << { message: message, call_stack: call_stack }
    end

    def relative(filename)
      filename.gsub(/#{@here}/, '.')
    end

    def call_stack
      caller.grep(/#{@here}/).map do |call|
        call.gsub(/\A#{@here}\/(.+)(:\d+):.+\z/, '\1\2')
      end
    end

    def summary_size
      5
    end

    def sorted_reports
      @sorted_reports ||= @reports.sort_by { |_, v| v }.reverse
    end

    def sort_description
      FactoryInspector::Report.sort_description
    end

    def header
      'FACTORY INSPECTOR: ' \
      "#{@reports.size} factories used, " \
      "#{total_calls} calls made over #{pretty_total_time}\n\n" \
      '  FACTORY NAME                     ' \
      "TOTAL  TOTAL     TIME PER  LONGEST   STRATEGIES\n" \
      '                                   ' \
      "CALLS  TIME (s)  CALL (s)  CALL (s)  USED\n"
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
      @reports.values.sum(&:total_time)
    end

    def total_calls
      @reports.values.sum(&:calls)
    end
  end
end
