# frozen_string_literal: true

module Macros
  # Macros for Penn data extraction and transformation
  module Penn
    NS = {
      tei: 'http://www.tei-c.org/ns/1.0',
      py: 'http://codespeak.net/lxml/objectify/pytype'
    }.freeze
    private_constant :NS

    # Map extracted values to appropriate penn_cho_edm_type values
    # @example
    #   penn_cho_edm_type => lambda { ... }
    # @return [Proc] a proc that traject can call for each record
    def penn_cho_edm_type
      lambda do |_record, accumulator|
        if accumulator[0]&.match('Cultural Artifact')
          accumulator.replace(['Image'])
        else
          accumulator.replace(['Text'])
        end
      end
    end

    # Map extracted values to appropriate penn_cho_has_type values
    # @example
    #   penn_cho_has_type => lambda { ... }
    # @return [Proc] a proc that traject can call for each record
    def penn_cho_has_type
      lambda do |_record, accumulator|
        if accumulator[0]&.match('Manuscript Frangment')
          accumulator.replace(['Manuscript'])
        elsif accumulator[0]&.match('Manuscript')
          accumulator.replace(['Manuscript'])
        else
          accumulator.replace(['Cultural Artifact'])
        end
      end
    end

    # @return [Proc] a proc that traject can call for each record
    def openn_source_url
      lambda do |record, accumulator|
        tei_path_ext = record.xpath('/*/*/dlme_url').map(&:text).first.gsub('/Data/', '')
        collection = tei_path_ext.split('/').first
        id = tei_path_ext.split('/').last.gsub('_TEI.xml', '')
        accumulator << "https://openn.library.upenn.edu/Data/#{collection}/html/#{id}.html"
      end
    end

    # @return [Proc] a proc that traject can call for each record
    def openn_thumbnail
      lambda do |record, accumulator|
        thumb_xpath = if record.xpath('/*/*/*/tei:facsimile/tei:surface[16]/tei:graphic[2]/@url', NS).map(&:text).first
                        record.xpath('/*/*/*/tei:facsimile/tei:surface[16]/tei:graphic[2]/@url', NS).map(&:text).first
                      elsif record.xpath('/*/*/*/tei:facsimile/tei:surface[8]/tei:graphic[2]/@url', NS).map(&:text).first
                        record.xpath('/*/*/*/tei:facsimile/tei:surface[8]/tei:graphic[2]/@url', NS).map(&:text).first
                      else
                        record.xpath('/*/*/*/tei:facsimile/tei:surface[1]/tei:graphic[2]/@url', NS).map(&:text).first
                      end
        tei_path_ext = record.xpath('/*/*/dlme_url').map(&:text).first.gsub('/Data/', '')
        collection = tei_path_ext.split('/').first
        id = tei_path_ext.split('/').last.gsub('_TEI.xml', '')
        accumulator << "https://openn.library.upenn.edu/Data/#{collection}/#{id}/data/#{thumb_xpath}"
      end
    end
  end
end
