require 'factory_inspector/inspector'
require 'method_profiler'

# User facing API, see README.md
module FactoryInspector
  def self.instrument
    @inspector ||= Inspector.new
    @profiler = MethodProfiler.observe(self)
    true
  end

  def self.results
    if @inspector.nil?
      warn 'WARNING: No FactoryInspector instrumentation found; ' \
           "did you forget to call 'FactoryInspector.instrument'?"
      false
    else
      @inspector.results
      $stderr.puts @profiler.report
      true
    end
  end
end
