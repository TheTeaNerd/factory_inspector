module FactoryInspector::Configuration

  def self.default_report_path
    File.expand_path(self.default_report_file, self.root_path)
  end

  def self.default_report_file
    'log/factory_inspector_report.txt'
  end

  def self.root_path
    File.expand_path(Dir.getwd)
  end

end

