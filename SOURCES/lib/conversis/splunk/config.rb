require 'yaml'

module Conversis
  module Splunk
    class Config
      attr_accessor :splunk_login, :splunk_password, :splunk_server

      def initialize()

        config_file = nil
        config_file_name = 'splunk.yml'
        if defined?(::Rails) && ::Rails.root && FileTest.exists?("#{::Rails.root.to_s}/config/#{config_file_name}")
          config_file = "#{::Rails.root.to_s}/config/#{config_file_name}"
        elsif FileTest.exists?("#{ENV['HOME']}/.#{config_file_name}")
          config_file = "#{ENV['HOME']}/.#{config_file_name}"
        elsif FileTest.exists?("/etc/#{config_file_name}")
          config_file = "/etc/#{config_file_name}"
        else
          raise "can't find configuration file"
        end

        env = defined?(::Rails) && ::Rails.env ? ::Rails.env : 'production'

        conf = YAML.load_file(config_file)[env]
        @splunk_login = conf['splunk_login']
        @splunk_password = conf['splunk_password']
        @splunk_server = conf['splunk_server']
      end
    end
  end
end
