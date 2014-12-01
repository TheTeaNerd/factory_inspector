require 'active_support/notifications'
require 'factory_inspector/report'
require 'factory_inspector/configuration'
require 'term/ansicolor'
require 'chronic_duration'

module FactoryInspector
  # Inspects the Factory via the callback `analyze`
  class Inspector
    class ::String
      include Term::ANSIColor
    end

    def initialize
      @here = Dir.getwd
      @local_call = /\A#{@here}/
      @reports = {}
      instrument_factory_girl
      @warnings = []
    end

    def generate_summary
      return if @reports.empty?

      puts "\n#{header(highlighted: true)}"
      slowest_reports.each { |_, report| puts report }
      puts "  (Slowest sorted by #{sort_description.to_s.cyan}.)"
    end

    def slowest_reports
      sorted_reports.take Configuration.summary_size
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

      print "\nFull report in '#{relative(filename).to_s.cyan}'"
    end

    def generate_warnings_log(filename: Configuration.default_warnings_path)
      return if @warnings.empty?

      file = File.open(filename, 'w')
      file.write("Factory Inspector - #{@warnings.size} warnings\n")
      @warnings.each do |warning|
        file.write("  * #{warning[:message]}\n")
        file.write("    * #{printable_call_stack(warning[:call_stack])}\n")
      end
      file.close

      print "\n#{@warnings.size} warning(s) in '#{relative(filename).to_s.cyan}'"
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
      caller.grep(@local_call).map do |call|
        call.gsub(/#{@local_call}\/(.+):(\d+):.+\z/, '\1:\2')
      end
    end

    def sorted_reports
      @sorted_reports ||= @reports.sort_by { |_, report| report }.reverse
    end

    def sort_description
      FactoryInspector::Report.sort_description
    end

    def header(highlighted: false)
        string = "FACTORY INSPECTOR: ".bold +
                 @reports.size.to_s.cyan + " factories used, ".bold +
                 total_calls.to_s.cyan + " calls made over ".bold +
                 pretty_total_time.to_s.cyan + "\n\n" +
                 "  FACTORY NAME                     TOTAL  TOTAL     TIME PER  LONGEST   STRATEGIES\n".bold +
                 '                                   CALLS  TIME (s)  CALL (s)  CALL (s)  USED'.bold +
                 "\n".reset

        highlighted ? string : string.uncolored
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
