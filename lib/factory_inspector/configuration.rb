module FactoryInspector
  # Responsible for all Configuration options
  module Configuration
    def self.default_report_path
      File.expand_path default_report_file, root_path
    end

    def self.default_warnings_log_path
      File.expand_path default_warnings_log_file, root_path
    end

    def self.default_report_file
      'log/factory_inspector.log'
    end

    def self.default_warnings_log_file
      'log/factory_inspector_warnings.log'
    end

    def self.root_path
      File.expand_path Dir.getwd
    end
  end
end
