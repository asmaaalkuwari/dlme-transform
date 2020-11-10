# frozen_string_literal: true

module Macros
  # Macros for extracting values from Lausanne records
  module Lausanne
    # Extracts earliest & latest dates from Lausanne record and merges into singe date range value
    def lausanne_date_range
      lambda do |record, accumulator, context|
        first_year = record['from'].to_i if record['from']&.match(/\d+/)
        last_year = record['to'].to_i if record['to']&.match(/\d+/)
        accumulator.replace(range_array(context, first_year, last_year))
      end
    end

    # Extracts earliest & latest dates from Lausanne record and merges into singe date string value
    def lausanne_date_string
      lambda do |record, accumulator|
        first_year = record['from'] if record['from']&.match(/\d+/)
        last_year = record['to'] if record['to']&.match(/\d+/)
        accumulator.replace(["#{first_year} - #{last_year}"]) if record['from'] || record['to']
      end
    end
  end
end
