require 'factory_inspector/inspector'

# User facing API, see README.md
module FactoryInspector
  def self.instrument
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
      true
    end
  end
end
