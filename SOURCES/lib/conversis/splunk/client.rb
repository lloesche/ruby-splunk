require 'net/https'
require 'cgi'
require 'uri'
require 'rexml/document'
require 'json'

module Conversis
  module Splunk
    class Client
      def initialize(options = {})
        defaults = {scheme: 'https', host: 'localhost', port: 8089, username: 'admin', password: 'changeme'}
        @options = defaults.merge(options)

        @session_key = get_session_key()
      end

      def search(query)
        options = { service_url: 'search/jobs',
                    post_data: {'search' => query}
        }
        xml = REXML::Document.new(splunk_request(options))
        search_id = REXML::XPath.first(xml, "//response/sid").text
      end

      def wait_for(search_id)
        options = { service_url: "search/jobs/#{search_id}" }
        search_is_done = false

        until search_is_done
          xml = REXML::Document.new(splunk_request(options))
          search_is_done = REXML::XPath.first(xml, "//s:key[@name='isDone']").text.to_i == 1
          sleep 3
        end
      end

      def results(search_id)
        options = { service_url: "search/jobs/#{search_id}/results",
                    get_params: {'output_mode' => 'json', 'count' => '0'}
        }
        JSON.parse(splunk_request(options))
      end

      private

      def get_session_key()
        options = { service_url: 'auth/login',
                    post_data: {'username' => @options[:username], "password" => @options[:password]}
        }
        xml = REXML::Document.new(splunk_request(options))
        REXML::XPath.first(xml, "//response/sessionKey").text
      end

      def splunk_request(options)
        get_params = options[:get_params].collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&') if !options[:get_params].nil?
        uri = URI.parse("#{@options[:scheme]}://#{@options[:host]}:#{@options[:port]}/services/#{options[:service_url]}#{get_params ? '?' + get_params : ''}")
        http = Net::HTTP.new(uri.host, uri.port)
        if @options[:scheme] == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        request = nil
        if options[:post_data].nil?
          request = Net::HTTP::Get.new uri.request_uri
        else
          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(options[:post_data])
        end
        
        request['Authorization'] = 'Splunk ' + @session_key if @session_key
        response = http.request(request)

        case response
        when Net::HTTPSuccess then return response.body
        else
          response.error!
        end
      end
    end
  end
end
