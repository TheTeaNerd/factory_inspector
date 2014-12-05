module FactoryInspector
  # Responsible for all Configuration options
  module Configuration
    def self.default_report_path
      File.expand_path default_report_file, default_report_dir
    end

    def self.default_warnings_path
      File.expand_path default_warnings_file, default_report_dir
    end

    def self.default_analysis_errors_path
      File.expand_path default_analysis_errors_file, default_report_dir
    end

    def self.default_report_dir
      File.expand_path default_report_dir_name, root_path
    end

    def self.default_report_dir_name
      'tmp'
    end

    def self.default_file_prefix
      'factory_inspector'
    end

    def self.default_report_file
      "#{default_file_prefix}.txt"
    end

    def self.default_warnings_file
      "#{default_file_prefix}_warnings.txt"
    end

    def self.default_analysis_errors_file
      "#{default_file_prefix}_analysis_errors.txt"
    end

    def self.root_path
      File.expand_path Dir.getwd
    end

    def self.summary_size
      3
    end
  end
end
