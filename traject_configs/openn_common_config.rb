# frozen_string_literal: true

require 'traject_plus'
require 'dlme_json_resource_writer'
require 'macros/date_parsing'
require 'macros/dlme'
require 'macros/normalize_language'
require 'macros/post_process'
require 'macros/tei'

extend Macros::DLME
extend Macros::DateParsing
extend Macros::PostProcess
extend Macros::Tei
extend Macros::NormalizeLanguage
extend TrajectPlus::Macros
extend TrajectPlus::Macros::Xml
extend TrajectPlus::Macros::Tei

settings do
  provide 'writer_class_name', 'DlmeJsonResourceWriter'
  provide 'reader_class_name', 'TrajectPlus::XmlReader'
end

# Cho Required
to_field 'id', lambda { |_record, accumulator, context|
  bare_id = default_identifier(context)
  accumulator << identifier_with_prefix(context, bare_id)
}

PUB_STMT = '/*/tei:teiHeader/tei:fileDesc/tei:publicationStmt'
to_field 'cho_publisher', extract_tei("#{PUB_STMT}/tei:publisher")
to_field 'cho_dc_rights', extract_tei("#{PUB_STMT}/tei:availability/tei:licence"), strip

MS_DESC = '/*/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc'
MS_ID = 'tei:msIdentifier'
to_field 'cho_identifier', extract_tei("#{MS_DESC}/#{MS_ID}/tei:idno[@type='call-number']")
to_field 'agg_is_shown_at' do |_record, accumulator, context|
  accumulator << transform_values(context, 'wr_id' => [extract_tei("#{MS_DESC}/#{MS_ID}/tei:altIdentifier[@type='openn-url']/tei:idno")])
end
to_field 'agg_preview' do |_record, accumulator, context|
  accumulator << transform_values(context, 'wr_id' => [openn_thumbnail])
end
to_field 'cho_edm_type', literal('Text')

MS_CONTENTS = 'tei:msContents'
to_field 'cho_description', extract_tei("#{MS_DESC}/#{MS_CONTENTS}/tei:summary")
to_field 'cho_language', extract_tei("#{MS_DESC}/#{MS_CONTENTS}/tei:textLang/@mainLang"), normalize_language

MS_ITEM = 'tei:msItem'
to_field 'cho_title', extract_tei("#{MS_DESC}/#{MS_CONTENTS}/#{MS_ITEM}/tei:title[1]")
to_field 'cho_creator', extract_tei("#{MS_DESC}/#{MS_CONTENTS}/#{MS_ITEM}/tei:author")

MS_ORIGIN = 'tei:history/tei:origin'
to_field 'cho_date', extract_tei("#{MS_DESC}/#{MS_ORIGIN}/tei:origDate")
to_field 'cho_spatial', extract_tei("#{MS_DESC}/#{MS_ORIGIN}/tei:origPlace")
to_field 'cho_provenance', extract_tei("#{MS_DESC}/tei:history/tei:provenance")

OBJ_DESC = 'tei:physDesc/tei:objectDesc'
to_field 'cho_extent', extract_tei("#{MS_DESC}/#{OBJ_DESC}/tei:layoutDesc/tei:layout")

SUPPORT_DESC = 'tei:supportDesc[@material="paper"]'
to_field 'cho_extent', extract_tei("#{MS_DESC}/#{OBJ_DESC}/#{SUPPORT_DESC}/tei:extent")

PROFILE_DESC = '/*/tei:teiHeader/tei:profileDesc/tei:textClass'
to_field 'cho_subject', extract_tei("#{PROFILE_DESC}/tei:keywords[@n='form/genre']/tei:term")
to_field 'cho_subject', extract_tei("#{PROFILE_DESC}/tei:keywords[@n='subjects']/tei:term")

# Provider fields [REQUIRED]
to_field 'agg_provider', provider, lang('en')
to_field 'agg_provider', provider_ar, lang('ar-Arab')
to_field 'agg_data_provider', data_provider, lang('en')
to_field 'agg_data_provider', data_provider_ar, lang('ar-Arab')
to_field 'agg_edm_rights', public_domain
to_field 'agg_provider_country', provider_country, lang('en')
to_field 'agg_provider_country', provider_country_ar, lang('ar-Arab')
to_field 'agg_data_provider_country', data_provider_country, lang('en')
to_field 'agg_data_provider_country', data_provider_country_ar, lang('ar-Arab')

each_record convert_to_language_hash('agg_data_provider', 'agg_data_provider_country', 'agg_provider', 'agg_provider_country', 'cho_title')