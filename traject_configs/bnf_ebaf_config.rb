# frozen_string_literal: true

to_field 'cho_contributor', extract_srw('dc:contributor'), strip
to_field 'cho_creator', extract_srw('dc:creator'), split('.'), first_only, strip
to_field 'cho_edm_type', extract_srw('dc:type'),
         first_only, strip, transform(&:downcase), translation_map('not_found', 'types', 'french-types')
to_field 'cho_language', extract_srw('dc:language'), first_only, strip, translation_map('marc_languages')

each_record convert_to_language_hash(
  'cho_contributor',
  'cho_creator',
  'cho_edm_type',
  'cho_language'
)
