require 'fileutils'
require 'pry'

module FactoryInspector
  module Reports
    def self.ensure_report_directory
      directory = Configuration.default_report_dir
      FileUtils.mkdir_p(directory) unless File.directory?(directory)

      glob = "#{directory}/#{Configuration.default_file_prefix}*"
      Dir.glob(glob).each do |old_report|
        begin
          File.delete old_report
        rescue SystemCallError => e
          $stderr.puts e.message
        end
      end
    end
  end
end
