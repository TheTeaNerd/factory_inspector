module FactoryInspector
  # Responsible for all Configuration options
  module Configuration
    def self.default_report_path
      File.expand_path default_report_file, root_path
    end

    def self.default_report_file
      'log/factory_inspector.txt'
    end

    def self.root_path
      File.expand_path Dir.getwd
    end
  end
end
