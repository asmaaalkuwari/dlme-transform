# frozen_string_literal: true

require 'parse_date'

# Macros for Traject transformations.
module Macros
  # Macros for parsing dates from Strings
  module DateParsing
    # get array of year values in range, when string is:
    # yyyy; yyyy; yyyy; yyyy; yyyy
    # works with negative years, but will return an emtpy set of a string is detected
    def array_from_range
      lambda do |_record, accumulator|
        return if accumulator.empty?

        range_years = accumulator.first.delete(' ')

        unless range_years.match?(/^[0-9-;]+$/)
          accumulator.replace([])
          return
        end

        accumulator.replace(range_years.split(';').map!(&:to_i))
      end
    end

    # given a string with date info, use parse_date gem to get an array of indicated years as integers
    #  See https://github.com/sul-dlss/parse_date for info on what it can parse
    def parse_range
      lambda do |_record, accumulator|
        range_years = []
        accumulator.each do |val|
          range_years << ParseDate.parse_range(val)
        end
        range_years.flatten!.uniq! if range_years.any?
        accumulator.replace(range_years)
      end
    end

    REGEX_OPTS = Regexp::IGNORECASE | Regexp::MULTILINE
    HIJRI_TAG = '(A.H.|AH|H)'
    HIJRI_TAG_B4_REGEX = Regexp.new("#{HIJRI_TAG}\s+(?<hijri>[^\(\)\/]*)", REGEX_OPTS)
    HIJRI_TAG_AFTER_REGEX = Regexp.new("(?<hijri>[^\(\)\/]*)\s+#{HIJRI_TAG}", REGEX_OPTS)

    # given an accumulator containing a string with both hijri and gregorian date info,
    #   change the accumulator contents to become only the hijri date info
    def parse_hijri
      lambda do |_record, accumulator|
        accumulator.map! do |val|
          hijri_val = Regexp.last_match(:hijri) if val.match(HIJRI_TAG_B4_REGEX)
          hijri_val = nil unless hijri_val&.match(/\d+/)
          hijri_val ||= Regexp.last_match(:hijri) if val.match(HIJRI_TAG_AFTER_REGEX)
          hijri_val&.strip
        end
      end
    end

    # given an accumulator containing a string with both hijri and gregorian date info,
    #   change the accumulator contents to become only the gregorian date info
    def parse_gregorian
      lambda do |_record, accumulator|
        accumulator.map! do |val|
          hijri_val = Regexp.last_match(:hijri) if val.match(HIJRI_TAG_B4_REGEX)
          hijri_val = nil unless hijri_val&.match(/\d+/)
          hijri_val ||= Regexp.last_match(:hijri) if val.match(HIJRI_TAG_AFTER_REGEX)
          return val unless hijri_val&.strip

          val.split(hijri_val).join
        end
      end
    end

    # Extracts earliest & latest dates from American Numismatic Society record and merges into single date range value
    # parse_range balks because there are values '-2100 - -2000' and it doesn't go that "low" for parse_range method
    # See https://github.com/sul-dlss/parse_date/issues/31 and https://github.com/sul-dlss/dlme-transform/issues/295
    def american_numismatic_date_range
      lambda do |_record, accumulator|
        return if accumulator.empty?

        val = accumulator.first
        dates = val.split('|')
        first_year = dates[0].to_i if dates[0]&.match(/\d+/)
        last_year = dates[1].to_i if dates[1]&.match(/\d+/)
        accumulator.replace(ParseDate.range_array(first_year, last_year))
      end
    end

    FGDC_NS = { fgdc: 'http://www.fgdc.gov/metadata/fgdc-std-001-1998.dtd' }.freeze
    FGDC_TIMEINFO_XPATH = '/metadata/idinfo/timeperd/timeinfo'
    FGDC_SINGLE_DATE_XPATH = "#{FGDC_TIMEINFO_XPATH}/sngdate/caldate"
    FGDC_DATE_RANGE_XPATH = "#{FGDC_TIMEINFO_XPATH}/rngdates"
    # Note:  saw no "#{FGDC_TIMEINFO_XPATH}/mdattim" multiple dates path data

    # Extracts dates from FGDC idinfo/timeperd to create a singe date range value
    # a year will be nil if it is NOT between -999 and (current year + 2), per parse_date gem
    # see https://www.fgdc.gov/metadata/csdgm/09.html, https://www.fgdc.gov/metadata/documents/MetadataQuickGuide.pdf
    def fgdc_date_range
      lambda do |record, accumulator, _context|
        date_range_nodeset = record.xpath(FGDC_DATE_RANGE_XPATH, FGDC_NS)
        if date_range_nodeset.present?
          first_year = ParseDate.earliest_year(date_range_nodeset.xpath('begdate', FGDC_NS)&.text&.strip)
          last_year = ParseDate.earliest_year(date_range_nodeset.xpath('enddate', FGDC_NS)&.text&.strip)
          accumulator.replace(ParseDate.range_array(first_year, last_year))
        else
          single_date_nodeset = record.xpath(FGDC_SINGLE_DATE_XPATH, FGDC_NS)
          accumulator.replace([ParseDate.earliest_year(single_date_nodeset.text&.strip)]) if single_date_nodeset.present?
        end
      end
    end

    # Extracts dates from slice of MARC 008 field
    #  to_field "date_range", extract_marc("008[06-14]"), marc_date_range
    #  or, if you have marcxml, get the correct bytes from 008 into the accumulator then call this
    # see https://www.loc.gov/marc/bibliographic/bd008a.html
    # does NOT work for BC dates (or negative dates) - because MARC 008 isn't set up for that
    def marc_date_range
      lambda do |_record, accumulator, _context|
        val = accumulator.first
        date_type = val[0]
        unless date_type.match?(/[cdeikmqrs]/)
          accumulator.replace([])
          return
        end

        # these work for date_type.match?([cdikmq])
        first_year = ParseDate.earliest_year(val[1..4])
        last_year = ParseDate.latest_year(val[5..8])
        if date_type.match?(/[se]/)
          last_year = ParseDate.latest_year(val[1..4])
        elsif date_type == 'r'
          first_year = ParseDate.earliest_year(val[5..8])
        end
        accumulator.replace(ParseDate.range_array(first_year, last_year))
      end
    end

    # Extracts earliest & latest dates from Met record and merges into singe date range value
    def met_date_range
      lambda do |record, accumulator, _context|
        first_year = record['objectBeginDate']
        last_year = record['objectEndDate']
        accumulator.replace(ParseDate.range_array(first_year, last_year))
      end
    end

    # Takes an existing array of year integers and returns an array converted to hijri
    # with an additional year added to the end to account for the non-365 day calendar
    def hijri_range
      lambda do |_record, accumulator, _context|
        return if accumulator.empty?

        accumulator.replace((
          Macros::DateParsing.to_hijri(accumulator.first)..Macros::DateParsing.to_hijri(accumulator.last) + 1).to_a)
      end
    end

    # Extracts earliest & latest dates from Penn museum record and merges into singe date range value
    def penn_museum_date_range
      lambda do |record, accumulator, _context|
        first_year = record['date_made_early'].to_i if record['date_made_early']&.match(/\d+/)
        last_year = record['date_made_late'].to_i if record['date_made_late']&.match(/\d+/)
        accumulator.replace(ParseDate.range_array(first_year, last_year))
      end
    end

    HIJRI_MODIFIER = 1.030684
    HIJRI_OFFSET = 621.5643

    # @param [Integer] a single year to be converted
    # @return [Integer] a converted integer year
    # This method uses the first formula provided here: https://en.wikipedia.org/wiki/Hijri_year#Formula
    def self.to_hijri(year)
      return unless year.is_a? Integer

      (HIJRI_MODIFIER * (year - HIJRI_OFFSET)).floor
    end
  end
end
