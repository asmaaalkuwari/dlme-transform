# frozen_string_literal: true

require 'active_support/benchmarkable'
require 'faraday'
require 'faraday_middleware'

module DLME
  # Misc. utilities for working with DLME data
  module Utils
    extend ActiveSupport::Benchmarkable

    def self.client
      Faraday.new do |builder|
        # builder.use :http_cache, store: Rails.cache
        builder.use FaradayMiddleware::FollowRedirects, limit: 3
        builder.adapter Faraday.default_adapter
      end
    end

    def self.fetch_json(uri)
      resp = benchmark("DLME::Utils.fetch_json(#{uri})", level: :debug) do
        client.get uri
      end
      resp_content_type = resp.headers['content-type']
      return ::JSON.parse(resp.body) if resp_content_type.start_with?('application/json')

      raise "Unexpected response type '#{resp_content_type}' for #{uri}"
    end

    def self.logger
      @logger ||= Logger.new(STDERR)
    end
  end
end
