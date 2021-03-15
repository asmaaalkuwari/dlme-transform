# frozen_string_literal: true

module Macros
  # DLME helpers for traject mappings
  module TitleExtraction
    NS = {
      dc: 'http://purl.org/dc/elements/1.1/',
      mods: 'http://www.loc.gov/mods/v3',
      oai: 'http://www.openarchives.org/OAI/2.0/',
      oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/',
      tei: 'http://www.tei-c.org/ns/1.0'
    }.freeze
    private_constant :NS

    # Extract a OAI Dublin Core title or, if no title in record, extract abridged description, else pass default values.
    def xpath_common_title_or_desc(xpath_title, xpath_desc, xpath_id)
      lambda do |rec, acc|
        title = rec.xpath(xpath_title, NS).map(&:text).first
        description = rec.xpath(xpath_desc, NS).map(&:text).first
        id = rec.xpath(xpath_id, NS).map(&:text).first
        if title.present?
          acc.replace(["#{title} #{id}"])
        elsif description.present?
          acc.replace([truncate(description)])
        end
      end
    end

    # Extract a OAI Dublin Core title or, if no title in record, extract abridged description, else pass default values.
    def xpath_title_or_desc(xpath_title, xpath_desc)
      lambda do |rec, acc|
        title = rec.xpath(xpath_title, NS).map(&:text).first
        description = rec.xpath(xpath_desc, NS).map(&:text).first
        if title.present?
          acc.replace([title])
        elsif description.present?
          acc.replace([truncate(description)])
        end
      end
    end

    # Extract a OAI Dublin Core title or, if no title in record, extract abridged description, else pass default values.
    def xpath_title_plus(xpath_title, xpath_other)
      lambda do |rec, acc|
        title = rec.xpath(xpath_title, NS).map(&:text).first
        other = rec.xpath(xpath_other, NS).map(&:text).first
        if title.present?
          if other.present?
            acc.replace(["#{title} #{truncate(other)}"])
          elsif other.present?
            acc.replace([truncate(other)])
          end
        end
      end
    end
  end
end