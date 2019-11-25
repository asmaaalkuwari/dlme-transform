# frozen_string_literal: true

require 'dlme_json_resource_writer'
require 'dlme_debug_writer'
require 'macros/date_parsing'
require 'macros/dlme'
require 'macros/each_record'
require 'macros/harvard'
require 'macros/normalize_language'
require 'macros/normalize_type'
require 'macros/timestamp'
require 'macros/version'
require 'traject_plus'

extend Macros::DLME
extend Macros::DateParsing
extend Macros::EachRecord
extend Macros::Harvard
extend Macros::NormalizeLanguage
extend Macros::NormalizeType
extend Macros::Timestamp
extend Macros::Version
extend TrajectPlus::Macros
extend TrajectPlus::Macros::Xml

settings do
  provide 'writer_class_name', 'DlmeJsonResourceWriter'
  provide 'reader_class_name', 'TrajectPlus::XmlReader'
end

# Set Version & Timestamp on each record
to_field 'transform_version', version
to_field 'transform_timestamp', timestamp

# Cho Required
to_field 'id', extract_harvard_identifier, strip
to_field 'cho_title', extract_harvard('/*/dc:title'), strip, first_only

# Cho Other
to_field 'cho_alternative', extract_harvard('/*/dc:title[last()]'), strip
to_field 'cho_contributor', extract_harvard('/*/dc:contributor'), strip
to_field 'cho_creator', extract_harvard('/*/dc:creator'), strip, lang('en')
to_field 'cho_date', extract_harvard('/*/dc:date'), strip, lang('en')
to_field 'cho_date_range_norm', extract_harvard('/*/dc:date'), strip, harvard_ihp_date_range
to_field 'cho_date_range_hijri', extract_harvard('/*/dc:date'), strip, harvard_ihp_date_range, hijri_range
to_field 'cho_description', extract_harvard('/*/dc:description'), strip, lang('en')
to_field 'cho_dc_rights', extract_harvard('/*/dc:rights'), strip, lang('en')
to_field 'cho_edm_type', extract_harvard('/*/dc:type[1]'), normalize_type, lang('en')
to_field 'cho_edm_type', extract_harvard('/*/dc:type[1]'), normalize_type, translation_map('norm_types_to_ar'), lang('ar-Arab')
to_field 'cho_format', extract_harvard('/*/dc:format'), strip, lang('en')
to_field 'cho_language', extract_harvard('/*/dc:language'),
         split(' '), first_only, strip, normalize_language, lang('en')
to_field 'cho_language', extract_harvard('/*/dc:language'),
         split(' '), first_only, strip, normalize_language, translation_map('norm_languages_to_ar'), lang('ar-Arab')
to_field 'cho_publisher', extract_harvard('/*/dc:publisher'), strip, lang('en')
to_field 'cho_relation', extract_harvard('/*/dc:relation'), strip, lang('en')
to_field 'cho_subject', extract_harvard('/*/dc:subject'), strip, lang('en')

# Agg
to_field 'agg_data_provider', data_provider, lang('en')
to_field 'agg_data_provider', data_provider_ar, lang('ar-Arab')
to_field 'agg_data_provider_country', data_provider_country, lang('en')
to_field 'agg_data_provider_country', data_provider_country_ar, lang('ar-Arab')
to_field 'agg_is_shown_at' do |_record, accumulator, context|
  accumulator << transform_values(
    context,
    'wr_id' => [extract_harvard('/*/dc:identifier[last()]'), strip]
  )
end
to_field 'agg_preview' do |_record, accumulator, context|
  accumulator << transform_values(
    context,
    'wr_id' => [extract_harvard_thumb]
  )
end
to_field 'agg_provider', provider, lang('en')
to_field 'agg_provider', provider_ar, lang('ar-Arab')
to_field 'agg_provider_country', provider_country, lang('en')
to_field 'agg_provider_country', provider_country_ar, lang('ar-Arab')

each_record convert_to_language_hash(
  'agg_data_provider',
  'agg_data_provider_country',
  'agg_provider',
  'agg_provider_country',
  'cho_alternative',
  'cho_contributor',
  'cho_coverage',
  'cho_creator',
  'cho_date',
  'cho_dc_rights',
  'cho_description',
  'cho_edm_type',
  'cho_extent',
  'cho_format',
  'cho_has_part',
  'cho_has_type',
  'cho_is_part_of',
  'cho_language',
  'cho_medium',
  'cho_provenance',
  'cho_publisher',
  'cho_relation',
  'cho_source',
  'cho_spatial',
  'cho_subject',
  'cho_temporal',
  'cho_title',
  'cho_type'
)

# NOTE: call add_cho_type_facet AFTER calling convert_to_language_hash fields
each_record add_cho_type_facet
