require 'active_support/notifications'
require 'factory_girl'

require 'factory_inspector/version'
require 'factory_inspector/configuration'
require 'factory_inspector/report'

module FactoryInspector

  def self.inspector
    @inspector ||= Inspector.new
  end

  def self.new
    self.inspector
  end

  def self.start_inspection
    self.inspector.start_inspection
  end

  def self.generate_report(output_filename=nil)
    report_file = output_filename || Configuration.default_report_path
    self.inspector.generate_report(report_file)
    puts "\nFactory Inspector report in '#{report_file}'"
    generate_summary
  end

  class Inspector

    def initialize
      @reports = {}
      instrument_factory_girl
    end

    def start_inspection
      @inspection_start_time = Time.now
    end

    def generate_summary
      puts "\n"
      puts print_header
      sorted_reports.take(10) do |report_name, report|
        puts print_formatted_report(report)
      end
    end

    def generate_report(output_filename)
      file = File.open(output_filename, 'w')
      file.write print_header
      sorted_reports.each do |report_name, report|
        file.write print_formatted_report(report)
      end
      file.close
    end

    # Callback for use by ActiveSupport::Notifications, not for end
    # user use directly though it has to be public for ActiveSupport
    # to see it.
    #
    # * [factory_name] Factory name
    # * [start_time] The start time of the factory call
    # * [finish_time] The finish time of the factory call
    # * [strategy] The strategy used when calling the factory
    #
    def analyze(factory_name, start_time, finish_time, strategy)
      if not @reports.has_key? factory_name
        @reports[factory_name] = FactoryInspector::Report.new(factory_name)
      end
      @reports[factory_name].update(finish_time - start_time, strategy)
    end

  private

    def sorted_reports
      @reports.sort_by{ |name,report| report.time_per_call_in_seconds }.reverse
    end

    def print_header
      header = ''
      header += "FACTORY INSPECTOR\n"
      header += "  - #{@reports.values.size} factories used, #{calculate_total_factory_calls} calls made\n"
      header += "  - #{sprintf("%6.4f",inspection_time_in_seconds)} seconds of testing inspected\n"
      #header += "  - #{sprintf("%6.4f",factory_time_in_seconds)} seconds in factories\n"
      #header += "  - #{sprintf("%4.1f",percentage_time_in_factories)}% testing time is factory calls\n"
      header += "\n"
      header += "  FACTORY NAME                     TOTAL  OVERALL   TIME PER  LONGEST   STRATEGIES\n"
      header += "                                   CALLS  TIME (s)  CALL (s)  CALL (s)            \n"
    end

    def print_formatted_report(report)
      sprintf("  %-30.30s % 5.0d    %8.4f    %5.5f  %5.4f      %s\n",
        report.factory_name,
        report.calls,
        report.total_time_in_seconds,
        report.time_per_call_in_seconds,
        report.worst_time_in_seconds,
        report.strategies)
    end

    def inspection_time_in_seconds
      @inspection_time_in_seconds ||= Time.now - @inspection_start_time
    end

    def percentage_time_in_factories
      ( (total_factory_time_in_seconds * 100) / inspection_time_in_seconds )
    end

    def instrument_factory_girl
      ActiveSupport::Notifications.subscribe('factory_girl.run_factory') do |name, start_time, finish_time, id, payload|
        analyze(payload[:name], start_time, finish_time, payload[:strategy])
      end
    end

    def total_factory_time_in_seconds
      @reports.values.reduce(0) do |total_time_in_seconds, report|
        total_time_in_seconds + report.total_time_in_seconds
      end
    end

    def calculate_total_factory_calls
      @reports.values.reduce(0) do |total_calls, report|
        total_calls + report.calls
      end
    end

  end

end
