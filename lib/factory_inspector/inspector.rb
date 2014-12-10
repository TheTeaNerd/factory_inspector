require 'active_support/notifications'
require 'chronic_duration'
require 'term/ansicolor'

require 'factory_inspector/analysis_error'
require 'factory_inspector/configuration'
require 'factory_inspector/factory_call'
require 'factory_inspector/report'
require 'factory_inspector/reports'

module FactoryInspector
  # Inspects the Factory via the callback `analyze_notification`
  class Inspector
    class ::String
      include Term::ANSIColor
    end

    def initialize
      @local_dir = Dir.getwd
      @local_call = /\A#{@local_dir}/
      @local_call_pattern = /#{@local_call}\/(.+:\d+):.+\z/
      @reports = {}
      @optimization_warnings = []
      @analysis_errors = []
      instrument_factory_girl
    end

    # Callback for use by ActiveSupport::Notifications.
    # Has to be public for ActiveSupport to use it.
    #
    # * [factory_name] Factory name
    # * [start_time] The start time of the factory call (seconds)
    # * [finish_time] The finish time of the factory call (seconds)
    # * [strategy] The strategy used when calling the factory
    #
    def analyze_notification(factory, start, finish, strategy)
      execution_time = (finish - start)
      if execution_time == 0.0
        message = "A call to :#{factory}##{strategy} took zero time; " \
                  'cannot analyse timing. Time may be frozen if a ' \
                  'Gem like TimeCop is being used?'
        @analysis_errors << AnalysisError.new(message: message, call_stack: call_stack)
      else
        @reports[factory] ||= Report.new(factory_name: factory)
        @reports[factory].update(time: execution_time,
                                 strategy: strategy,
                                 call_stack: call_stack)
      end
      nil
    end

    def results
      return if @reports.empty?

      Reports.ensure_report_directory
      generate_analysis
      generate_summary
      generate_report
      generate_analysis_errors_report
      generate_optimization_warnings
    end

    private

    def generate_summary
      puts "\n#{header(highlighted: true)}"
      slowest_reports.each { |_factory, report| puts report }
      puts "  (Slowest sorted by #{highlight sort_description}.)"
    end

    def generate_analysis
      @reports.values.each do |report|
        @reports.values.each do |other_report|
          matching_calls = report.called_by? other_report
          if matching_calls
            other_report.factories_called << report.factory_name
            $stderr.puts "\nThere are #{matching_calls.size} matching calls when #{report.factory_name} is called by #{other_report.factory_name}".red

            build_calls = matching_calls.select do |matching_call|
              matching_call.caller.build?
            end
            build_calls.each do |build_call|
              called_creates = build_call.called.select(&:create?)
              called_creates.each do |call|
                @optimization_warnings << Hashr.new(caller: build_call.caller, called: call)
              end
            end
          end
        end
      end
    end

    def slowest_reports
      sorted_reports.take Configuration.summary_size
    end

    def generate_report(filename: Configuration.default_report_path)
      file = File.open(filename, 'w')
      file.write header

      reports = sorted_reports
      reports.each { |_factory, report| file.write report }

      file.write("\n\nComplete caller information for each factory:\n")
      reports.each do |_factory, report|
        file.write "\nFACTORY: '#{report.factory_name}'\n"
        file.write "  - Called #{report.number_of_calls} times\n"
        if report.factories_called.empty?
          file.write "  - Calls no other factories.\n"
        else
          file.write "  - Calls factory #{report.factories_called.map { |factory| ":#{factory}" }.join(' and ')}\n"
        end
        file.write report.all_calls
      end
      file.close

      print "\nFull report in '#{highlight(relative(filename))}'"
    end

    def generate_optimization_warnings(filename: Configuration.default_warnings_path)
      return if @optimization_warnings.empty?

      file = File.open(filename, 'w')
      file.write("#{@optimization_warnings.size} optimization warning(s)\n\n")
      file.write("These warnings are for a Build strategy calling Create: in-memory strategy triggering DB creates are a common cause of slow tests, and are usually triggered via associations.\n\n")

      @optimization_warnings.each do |warning|
        file.write("  * :#{warning.caller.factory}##{warning.caller.strategy} -> #{warning.called}\n")
      end
      file.close

      print "\n#{@optimization_warnings.size} optimization warning(s) in '#{highlight(relative(filename))}'"
    end

    def generate_analysis_errors_report(filename: Configuration.default_analysis_errors_path)
      return if @analysis_errors.empty?

      file = File.open(filename, 'w')
      file.write("#{@analysis_errors.size} analysis error(s)\n\n")
      @analysis_errors.each do |analysis_error|
        file.write("  * #{analysis_error.message}\n")
        file.write("    * #{analysis_error.printable_call_stack}\n")
      end
      file.close

      print "\n#{@analysis_errors.size} analysis errors(s) in '#{highlight(relative(filename))}'"
    end

    def relative(filename)
      filename.gsub(/#{@local_dir}/, '.')
    end

    def call_stack
      caller.grep(@local_call) do |call|
        call.gsub(@local_call_pattern, '\1')
      end
    end

    def sorted_reports
      @sorted_reports ||= @reports.sort_by { |_, report| report }.reverse
    end

    def sort_description
      FactoryInspector::Report.sort_description
    end

    def header(highlighted: false)
      string = 'FACTORY INSPECTOR: '.bold +
               highlight(@reports.size) + ' factories used, '.bold +
               highlight(total_number_of_calls) + ' calls made over '.bold +
               highlight(pretty_total_time) + "\n\n" +
               "  FACTORY NAME                   TOTAL  TOTAL     TIME PER  LONGEST   STRATEGIES\n".bold +
               '                                 CALLS  TIME (s)  CALL (s)  CALL (s)  USED'.bold +
               "\n".reset

      highlighted ? string : string.uncolored
    end

    def instrument_factory_girl
      event = 'factory_girl.run_factory'
      notifications = ActiveSupport::Notifications
      notifications.subscribe(event) do |_, start, finish, _, payload|
        analyze_notification(payload[:name], start, finish, payload[:strategy])
      end
    end

    def pretty_total_time
      ChronicDuration.output(total_time.round(2), keep_zero: true)
    end

    def total_time
      @reports.values.sum(&:total_time)
    end

    def total_number_of_calls
      @reports.values.sum(&:number_of_calls)
    end

    def highlight(string)
      string.to_s.cyan
    end
  end
end
