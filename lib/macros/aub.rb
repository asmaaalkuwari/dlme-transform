# frozen_string_literal: true

module Macros
  # Macros for extracting values from Nokogiri documents
  module AUB
    NS = {
      oai: 'http://www.openarchives.org/OAI/2.0/',
      dc: 'http://purl.org/dc/elements/1.1/',
      oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    }.freeze
    private_constant :NS

    PREFIX = '/oai_dc:dc'
    private_constant :PREFIX

    include Traject::Macros::NokogiriMacros

    # Extracts values for the given xpath which is prefixed with oai and oai_dc wrappers
    # @example
    #   extract_oai('dc:language') => lambda { ... }
    # @param [String] xpath the xpath query expression
    # @return [Proc] a proc that traject can call for each record
    def extract_poha(xpath)
      extract_xpath(xpath.to_s, ns: NS)
    end

    # Extracts values for the given xpath which is prefixed with oai and oai_dc wrappers
    # while ignoring the thumbmnail urls in the description field
    # @example
    #   extract_oai('dc:language') => lambda { ... }
    # @param [String] xpath the xpath query expression
    # @return [Proc] a proc that traject can call for each record
    def extract_aub_description
      lambda do |record, accumulator|
        node = record.xpath('/*/*/*/dc:description', NS)
        values = []
        node.each do |val|
          values.append(val&.content&.strip) unless val&.content&.strip&.start_with?('http')
        end
        accumulator.replace(values)
      end
    end
  end
end
