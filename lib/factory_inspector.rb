require 'factory_inspector/configuration'
require 'factory_inspector/inspector'

# Inspects Factories while running and generates reports
module FactoryInspector
  def self.instrument
    @inspector ||= Inspector.new
  end

  def self.generate_report(filename: Configuration.default_report_path)
    @inspector.generate_summary
    @inspector.generate_report filename
  end
end
