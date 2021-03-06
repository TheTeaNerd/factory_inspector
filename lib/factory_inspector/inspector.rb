require 'active_support/notifications'
require 'chronic_duration'
require 'term/ansicolor'

require 'factory_inspector/analysis_error'
require 'factory_inspector/configuration'
require 'factory_inspector/factory_call'
require 'factory_inspector/human_counts'
require 'factory_inspector/report'
require 'factory_inspector/reports'

module FactoryInspector
  # Inspects the Factory via the callback `analyze_notification`
  class Inspector
    include ::FactoryInspector::HumanCounts

    class ::String
      include Term::ANSIColor
    end

    def initialize
      @local_dir = Dir.getwd
      @reports = {}
      @optimization_warnings = []
      @analysis_errors = []
      @analyze_notification_calls = 0
      instrument_factory_girl

      @local_call = /\A#{@local_dir}/
      @local_pattern = /#{@local_call}\/(.+:\d+):.+\z/
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
      call_stack = dump_call_stack
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
      @analyze_notification_calls += 1
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
          next if report == other_report

          matching_calls = report.called_by? other_report
          if matching_calls
            other_report.factories_called << report.factory_name

            matching_calls.select { |match| match.caller.build? }
                          .each do |build_call|
              build_call.called.select(&:create?).each do |call|
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
      file.write("#{@optimization_warnings.size} optimization warning(s) - ")
      file.write("In-memory :build strategy calls are calling DB-hitting :create calls; this is usually unintended and triggered via associations in the Factory or Model.\n\n")

      collapsed_warnings = @optimization_warnings.each_with_object(Hash.new(0)) do |warning, counts|
        counts[warning] += 1
      end
      collapsed_warnings.each do |warning, count|
        file.write("  * #{warning.caller.description} calls #{warning.called.description} #{human_count count} due to #{warning.called.printable_stack} (#{warning.called.description})\n")
      end
      file.close

      print "\n#{@optimization_warnings.size} optimization warning(s) in '#{highlight(relative(filename))}'"
    end

    def generate_analysis_errors_report(filename: Configuration.default_analysis_errors_path)
      return if @analysis_errors.empty?

      file = File.open(filename, 'w')
      file.write("#{@analysis_errors.size} analysis error(s)\n\n")


      collapsed_errors = @analysis_errors.each_with_object(Hash.new(0)) do |errors, counts|
        counts[errors] += 1
      end
      collapsed_errors.each_with_index do |(analysis_error, count), index|
        file.write("  #{index}. #{analysis_error.message}\n")
        file.write("    * #{analysis_error.printable_call_stack}#{count > 1 ? " (#{count} occurences)" : ''}\n")
      end
      file.close

      print "\n#{@analysis_errors.size} analysis errors(s) in '#{highlight(relative(filename))}'"
    end

    def relative(filename)
      filename.gsub(/#{@local_dir}/, '.')
    end

    def dump_call_stack
      caller.grep(@local_call) do |call|
        call.gsub(@local_pattern, '\1')
      end.uniq.reverse
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
      @pretty_total_time ||= ChronicDuration.output(total_time.round(2), keep_zero: true)
    end

    def total_time
      @reports.values.sum(&:total_time)
    end

    def total_number_of_calls
      @analyze_notification_calls
    end

    def highlight(string)
      string.to_s.cyan
    end
  end
end
