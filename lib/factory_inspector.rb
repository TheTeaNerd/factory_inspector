require 'factory_inspector/inspector'

# User facing API
module FactoryInspector
  def self.instrument
    @inspector ||= Inspector.new
    true
  end

  def self.results
    if @inspector.nil?
      warn 'WARNING: No FactoryInspector instrumentation found; ' \
           "did you forget to call 'FactoryInspector.instrument'?"
    else
      @inspector.generate_summary
      @inspector.generate_report
    end
    true
  end
end
