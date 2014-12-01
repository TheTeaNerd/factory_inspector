module FactoryInspector
  # Responsible for all Configuration options
  module Configuration
    def self.default_report_path
      File.expand_path default_report_file, root_path
    end

    def self.default_warnings_path
      File.expand_path default_warnings_file, root_path
    end

    def self.default_report_file
      'log/factory_inspector.txt'
    end

    def self.default_warnings_file
      'log/factory_inspector_warnings.txt'
    end

    def self.root_path
      File.expand_path Dir.getwd
    end

    def self.summary_size
      5
    end
  end
end
