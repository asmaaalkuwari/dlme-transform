# frozen_string_literal: true

module Macros
  # DLME helpers for traject mappings
  module DLME
    # Returns the provider as specified in the ++agg_provider++ field of ++metadata_mapping.json++
    # @return [Proc] a proc that traject can call for each record
    # @example
    #  provider => "Bibliothèque nationale de France"
    def provider
      from_settings('agg_provider')
    end

    # Returns the data provider as specified in the ++agg_data_provider++ field of ++metadata_mapping.json++
    # @return [Proc] a proc that traject can call for each record
    # @example
    #  data_provider => "SALT Galata"
    def data_provider
      from_settings('agg_data_provider')
    end

    # Returns the given identifier prefixed with the ++inst_id++  as specified in ++metadata_mapping.json++
    # @param [Traject::Indexer::Context] context
    # @param [String] identifier
    # @return [String] a prefixed record identifier
    # @example
    #  # when settings contains: "inst_id"=>"salt"
    #
    #  identifier_with_prefix(context, '123') => "salt_123"
    def identifier_with_prefix(context, identifier)
      return identifier unless context.settings.key?('inst_id')

      prefix = context.settings.fetch('inst_id') + '_'

      if identifier.start_with? prefix
        identifier
      else
        prefix + identifier
      end
    end

    # Create an identifier that can be used in case none is encoded in the record.
    # It will first try to take it from the ++command_line.filename++ setting and
    # if that is not available, from the `identifier` setting.
    # @return [String] a record identifier
    # @example
    #  # when settings contains: "command_line.filename"=>"data/penn/schoenberg/data/ljs407.xml"
    #
    #  default_identifier(context) => 'ljs407'
    def default_identifier(context)
      identifier = if context.settings.key?('command_line.filename')
                     context.settings.fetch('command_line.filename')
                   elsif context.settings.key?('identifier')
                     context.settings.fetch('identifier')
                   end
      File.basename(identifier, File.extname(identifier)) if identifier.present?
    end

    private

    def from_settings(field)
      lambda { |_record, accumulator, context|
        accumulator << context.settings.fetch(field)
      }
    end
  end
end
