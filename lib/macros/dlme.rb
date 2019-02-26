# frozen_string_literal: true

module Macros
  # DLME helpers for traject mappings
  module DLME
    LOC_NS = {
      dc: 'http://purl.org/dc/elements/1.1/',
      oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/',
      srw: 'http://www.loc.gov/zing/srw/'
    }.freeze

    def provider
      from_settings('agg_provider')
    end

    def data_provider
      from_settings('agg_data_provider')
    end

    def from_settings(field)
      lambda { |_record, accumulator, context|
        accumulator << context.settings.fetch(field)
      }
    end

    def identifier_with_prefix(context, identifier)
      return identifier unless context.settings.key?('inst_id')

      prefix = context.settings.fetch('inst_id') + '_'

      if identifier.start_with? prefix
        identifier
      else
        prefix + identifier
      end
    end

    def default_identifier(context)
      identifier = if context.settings.key?('command_line.filename')
                     context.settings.fetch('command_line.filename')
                   elsif context.settings.key?('identifier')
                     context.settings.fetch('identifier')
                   end
      File.basename(identifier, File.extname(identifier)) if identifier.present?
    end
  end
end
