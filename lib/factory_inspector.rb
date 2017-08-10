require 'factory_inspector/inspector'
require 'factory_inspector/report'
require 'method_profiler'

# User facing API, see README.md
module FactoryInspector
  def self.profile
    false
  end

  def self.instrument
    classes_to_profile = [FactoryCall]

    @profilers = classes_to_profile.map do |class_to_profile|
      MethodProfiler.observe class_to_profile
    end
    @inspector ||= Inspector.new
    true
  end

  def self.results
    if @inspector.nil?
      warn 'WARNING: No FactoryInspector instrumentation found; ' \
           "did you forget to call 'FactoryInspector.instrument'?"
      false
    else
      @inspector.results
      if profile
        $stderr.puts "\n"
        @profilers.each do |profiler|
          $stderr.puts "\n"
          $stderr.puts profiler.report.sort_by(:total_time)
        end
      end
      true
    end
  end
end
