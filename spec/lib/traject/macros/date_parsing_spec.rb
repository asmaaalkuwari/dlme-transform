# frozen_string_literal: true

require 'macros/date_parsing'

RSpec.describe Macros::DateParsing do
  subject(:indexer) do
    Traject::Indexer.new.tap do |indexer|
      indexer.instance_eval do
        extend TrajectPlus::Macros
        extend Macros::DateParsing
      end
    end
  end

  let(:raw_val_lambda) do
    lambda do |record, accumulator|
      accumulator << record[:raw]
    end
  end

  describe '#array_from_range' do
    before do
      indexer.instance_eval do
        to_field 'int_array', accumulate { |record, *_| record[:value] }, array_from_range
      end
    end

    it 'gets a range of years' do
      expect(indexer.map_record(value: '1880; 1881; 1882; 1883; 1884')).to include 'int_array' => [1880, 1881, 1882, 1883, 1884]
    end

    it 'gets a range of negative years' do
      expect(indexer.map_record(value: '-881; -880; -879; -878; -877')).to include 'int_array' => [-881, -880, -879, -878, -877]
    end

    it 'gets a string' do
      expect(indexer.map_record(value: 'ca. late 19th century')).to be_empty
    end

    it 'gets a nil value' do
      expect(indexer.map_record(value: nil)).to be_empty
    end
  end

  describe '#parse_range' do
    before do
      indexer.instance_eval do
        to_field 'int_array', accumulate { |record, *_| record[:value] }, parse_range
      end
    end

    it 'parseable values' do
      expect(indexer.map_record(value: '2019')).to include 'int_array' => [2019]
      expect(indexer.map_record(value: '12/25/00')).to include 'int_array' => [2000]
      expect(indexer.map_record(value: '5-1-25')).to include 'int_array' => [1925]
      expect(indexer.map_record(value: '-914')).to include 'int_array' => [-914]
      expect(indexer.map_record(value: '1666 B.C.')).to include 'int_array' => [-1666]
      expect(indexer.map_record(value: '2017-2019')).to include 'int_array' => [2017, 2018, 2019]
      expect(indexer.map_record(value: 'between 1830 and 1899?')).to include 'int_array' => (1830..1899).to_a
      expect(indexer.map_record(value: '196u')).to include 'int_array' => (1960..1969).to_a
      expect(indexer.map_record(value: '17--')).to include 'int_array' => (1700..1799).to_a
      expect(indexer.map_record(value: '1602 or 1603')).to include 'int_array' => [1602, 1603]
      expect(indexer.map_record(value: 'between 300 and 150 B.C')).to include 'int_array' => (-300..-150).to_a
      expect(indexer.map_record(value: '18th century CE')).to include 'int_array' => (1700..1799).to_a
      expect(indexer.map_record(value: 'ca. 10th–9th century B.C.')).to include 'int_array' => (-1099..-900).to_a
      expect(indexer.map_record(value: 'Sun, 12 Nov 2017 14:08:12 +0000')).to include 'int_array' => [2017] # aims
    end

    it 'when missing date' do
      expect(indexer.map_record({})).to eq({})
    end
  end

  mixed_hijri_gregorian =
    [ # raw, hijri part, gregorian part
      # openn
      ['A.H. 986 (1578)', '986', '1578'],
      ['A.H. 899 (1493-1494)', '899', '1493-1494'],
      ['A.H. 901-904 (1496-1499)', '901-904', '1496-1499'],
      ['A.H. 1240 (1824)', '1240', '1824'],
      ['A.H. 1258? (1842)', '1258?', '1842'],
      ['A.H. 1224, 1259 (1809, 1843)', '1224, 1259', '1809, 1843'],
      ['A.H. 1123?-1225 (1711?-1810)', '1123?-1225', '1711?-1810'],
      ['ca. 1670 (A.H. 1081)', '1081', 'ca. 1670'],
      ['1269 A.H. (1852)', '1269', '1852'],
      # cambridge islamic
      ['628 A.H. / 1231 C.E.', '628', '1231 C.E.'],
      ['974 AH / 1566 CE', '974', '1566 CE'],
      # sakip-sabanci Kitapvehat
      ['887 H (1482 M)', '887', '1482 M'],
      ['1269, 1272, 1273 H (1853, 1855, 1856 M)', '1269, 1272, 1273', '1853, 1855, 1856 M'],
      ['1194 H (1780 M)', '1194', '1780 M'],
      ['1101 H (1689-1690 M)', '1101', '1689-1690 M'],
      ['1240, 1248 H (1825, 1832 M)', '1240, 1248', '1825, 1832 M'],
      ['1080 H (1669-1670 M)', '1080', '1669-1670 M'],
      ['1076 H (1665-1666)', '1076', '1665-1666'],
    ]

  describe '#parse_gregorian' do
    before do
      indexer.instance_eval do
        to_field 'gregorian', accumulate { |record, *_| record[:value] }, parse_gregorian
      end
    end
    mixed_hijri_gregorian.each do |raw, exp_hijri, exp_gregorian|
      it "#{raw} results in string containing '#{exp_gregorian}' and not '#{exp_hijri}'" do
        result = indexer.map_record(value: raw)['gregorian'].first
        expect(result).to match(Regexp.escape(exp_gregorian))
        expect(result).not_to match(Regexp.escape(exp_hijri))
      end
    end

    it 'no hijri present - assumes gregorian' do
      expect(indexer.map_record(value: '1894.')).to include 'gregorian' => ['1894.']
      expect(indexer.map_record(value: '1890-')).to include 'gregorian' => ['1890-']
      expect(indexer.map_record(value: '1886-1887')).to include 'gregorian' => ['1886-1887']
      # harvard ihp -  Gregorian is within square brackets - handled in diff macro
      expect(indexer.map_record(value: '1322 [1904]')).to include 'gregorian' => ['1322 [1904]']
      expect(indexer.map_record(value: '1317 [1899 or 1900]')).to include 'gregorian' => ['1317 [1899 or 1900]']
      expect(indexer.map_record(value: '1288 [1871-72]')).to include 'gregorian' => ['1288 [1871-72]']
      expect(indexer.map_record(value: '1254 [1838 or 39]')).to include 'gregorian' => ['1254 [1838 or 39]']
    end

    it 'only hijri present - no parseable valid gregorian' do
      result = indexer.map_record(value: '1225 H')['gregorian'].first
      expect(result).not_to match(Regexp.escape('1225'))
    end

    it 'missing value' do
      expect(indexer.map_record({})).to eq({})
    end
  end

  describe '#parse_hijri' do
    before do
      indexer.instance_eval do
        to_field 'hijri', accumulate { |record, *_| record[:value] }, parse_hijri
      end
    end

    mixed_hijri_gregorian.each do |raw, exp_hijri, _exp_gregorian|
      it "#{raw} results in string matching '#{exp_hijri}'" do
        expect(indexer.map_record(value: raw)).to include 'hijri' => [exp_hijri]
      end
    end

    it 'unparseable values' do
      # values like these are assumed to be gregorian
      expect(indexer.map_record(value: '1894.')).to eq({})
      expect(indexer.map_record(value: '1890-')).to eq({})
      expect(indexer.map_record(value: '1886-1887')).to eq({})
      # harvard ihp -  hijri is outside/before square brackets - handled in diff macro
      expect(indexer.map_record(value: '1322 [1904]')).to eq({})
      expect(indexer.map_record(value: '1317 [1899 or 1900]')).to eq({})
      expect(indexer.map_record(value: '1288 [1871-72]')).to eq({})
      expect(indexer.map_record(value: '1254 [1838 or 39]')).to eq({})
    end

    it 'missing value' do
      expect(indexer.map_record({})).to eq({})
    end
  end

  describe '#fgdc_date_range' do
    before do
      indexer.instance_eval do
        to_field 'range', fgdc_date_range
      end
    end

    context 'when rngdates element provided' do
      it 'range is from begdate to enddate' do
        rec_str = <<-XML
          <?xml version="1.0" encoding="utf-8" ?>
          <!DOCTYPE metadata SYSTEM "http://www.fgdc.gov/metadata/fgdc-std-001-1998.dtd">
          <metadata>
            <idinfo>
              <timeperd>
                <timeinfo>
                  <rngdates>
                    <begdate>19990211</begdate>
                    <enddate>20000222</enddate>
                  </rngdates>
                </timeinfo>
              </timeperd>
            </idinfo>
          </metadata>
        XML
        ng_rec = Nokogiri::XML.parse(rec_str)
        expect(indexer.map_record(ng_rec)).to include 'range' => [1999, 2000]
      end
    end
    context 'when single date provided' do
      it 'range is a single value Array' do
        rec_str = <<-XML
        <?xml version="1.0" encoding="utf-8" ?>
        <!DOCTYPE metadata SYSTEM "http://www.fgdc.gov/metadata/fgdc-std-001-1998.dtd">
        <metadata>
          <idinfo>
            <timeperd>
              <timeinfo>
                <sngdate>
                  <caldate>1725</caldate>
                </sngdate>
              </timeinfo>
            </timeperd>
          </idinfo>
        </metadata>
        XML
        ng_rec = Nokogiri::XML.parse(rec_str)
        expect(indexer.map_record(ng_rec)).to include 'range' => [1725]
      end
      it 'year in future results in no value' do
        rec_str = <<-XML
        <?xml version="1.0" encoding="utf-8" ?>
        <!DOCTYPE metadata SYSTEM "http://www.fgdc.gov/metadata/fgdc-std-001-1998.dtd">
        <metadata>
          <idinfo>
            <timeperd>
              <timeinfo>
                <sngdate>
                  <caldate>2725</caldate>
                </sngdate>
              </timeinfo>
            </timeperd>
          </idinfo>
        </metadata>
        XML
        ng_rec = Nokogiri::XML.parse(rec_str)
        expect(indexer.map_record(ng_rec)).not_to include 'range'
      end
    end
  end

  describe '#hijri_range' do
    before do
      indexer.instance_eval do
        to_field 'int_array', accumulate { |record, *_| record[:value] }, hijri_range
      end
    end

    it 'receives a range of integers' do
      expect(indexer.map_record(value: [2010, 2011, 2012])).to include 'int_array' => [1431, 1432, 1433, 1434]
    end

    it 'receives a single value' do
      expect(indexer.map_record(value: [623])).to include 'int_array' => [1, 2]
    end

    it 'is not provided a value' do
      expect(indexer.map_record(value: [])).to be_empty
    end

    it 'receives a bc value' do
      expect(indexer.map_record(value: [-10, -9, -8])).to include 'int_array' => [-651, -650, -649, -648]
    end
  end

  describe '#marc_date_range' do
    {
      # 008[06-14] => expected result
      'e20070615' => [2007],
      'i17811799' => (1781..1799).to_a,
      'k08uu09uu' => (800..999).to_a,
      'm19721975' => (1972..1975).to_a,
      'q159u159u' => (1590..1599).to_a,
      'r19701916' => [1916],
      'r19uu1922' => [1922],
      's1554    ' => [1554],
      's15uu    ' => (1500..1599).to_a,
      's193u    ' => (1930..1939).to_a,
      's08uu    ' => (800..899).to_a
    }.each_pair do |raw_val, expected|
      it "#{raw_val} from 008[06-14] gets correct result" do
        indexer.to_field('range', raw_val_lambda, indexer.marc_date_range)
        expect(indexer.map_record(raw: raw_val)).to include 'range' => expected
      end
    end

    [
      't19821949', # date range not valid
      'a19992000' # unrecognized date_type 'a'
    ].each do |raw_val|
      it "#{raw_val} from 008[06-14] has no value as expected" do
        indexer.to_field('range', raw_val_lambda, indexer.marc_date_range)
        expect(indexer.map_record(raw: raw_val)).to eq({})
      end
    end
  end

  describe '#met_date_range' do
    before do
      indexer.instance_eval do
        to_field 'range', met_date_range
      end
    end

    context 'when objectBeginDate and objectEndDate populated' do
      it 'both dates and range are valid' do
        expect(indexer.map_record('objectBeginDate' => '-2', 'objectEndDate' => '1')).to include 'range' => [-2, -1, 0, 1]
        expect(indexer.map_record('objectBeginDate' => '-11', 'objectEndDate' => '1')).to include 'range' => (-11..1).to_a
        expect(indexer.map_record('objectBeginDate' => '-100', 'objectEndDate' => '-99')).to include 'range' => [-100, -99]
        expect(indexer.map_record('objectBeginDate' => '-1540', 'objectEndDate' => '-1538')).to include 'range' => (-1540..-1538).to_a
        expect(indexer.map_record('objectBeginDate' => '0', 'objectEndDate' => '99')).to include 'range' => (0..99).to_a
        expect(indexer.map_record('objectBeginDate' => '1', 'objectEndDate' => '10')).to include 'range' => (1..10).to_a
        expect(indexer.map_record('objectBeginDate' => '300', 'objectEndDate' => '319')).to include 'range' => (300..319).to_a
        expect(indexer.map_record('objectBeginDate' => '666', 'objectEndDate' => '666')).to include 'range' => [666]
      end

      it 'invalid range raises exception' do
        exp_err_msg = 'unable to create year range array from 1539, 1292'
        expect { indexer.map_record('objectBeginDate' => '1539', 'objectEndDate' => '1292') }.to raise_error(StandardError, exp_err_msg)
      end
    end

    it 'when one date is empty, range is a single year' do
      expect(indexer.map_record('objectBeginDate' => '300')).to include 'range' => [300]
      expect(indexer.map_record('objectEndDate' => '666')).to include 'range' => [666]
    end

    it 'when both dates are empty, no error is raised' do
      expect(indexer.map_record({})).to eq({})
    end

    it 'date strings with text and numbers are interpreted as 0' do
      expect(indexer.map_record('date_made_early' => 'not999', 'date_made_late' => 'year of 1939')).to eq({})
    end
  end

  describe '#penn_museum_date_range' do
    before do
      indexer.instance_eval do
        to_field 'range', penn_museum_date_range
      end
    end

    context 'when date_made_early and date_made_late populated' do
      it 'both dates and range are valid' do
        expect(indexer.map_record('date_made_early' => '-2', 'date_made_late' => '1')).to include 'range' => [-2, -1, 0, 1]
        expect(indexer.map_record('date_made_early' => '-11', 'date_made_late' => '1')).to include 'range' => (-11..1).to_a
        expect(indexer.map_record('date_made_early' => '-100', 'date_made_late' => '-99')).to include 'range' => [-100, -99]
        expect(indexer.map_record('date_made_early' => '-1540', 'date_made_late' => '-1538')).to include 'range' => (-1540..-1538).to_a
        expect(indexer.map_record('date_made_early' => '0', 'date_made_late' => '99')).to include 'range' => (0..99).to_a
        expect(indexer.map_record('date_made_early' => '1', 'date_made_late' => '10')).to include 'range' => (1..10).to_a
        expect(indexer.map_record('date_made_early' => '300', 'date_made_late' => '319')).to include 'range' => (300..319).to_a
        expect(indexer.map_record('date_made_early' => '666', 'date_made_late' => '666')).to include 'range' => [666]
      end

      it 'invalid range raises exception' do
        exp_err_msg = 'unable to create year range array from 1539, 1292'
        expect { indexer.map_record('date_made_early' => '1539', 'date_made_late' => '1292') }.to raise_error(StandardError, exp_err_msg)
      end

      it 'future date year raises exception' do
        exp_err_msg = 'unable to create year range array from 1539, 2050'
        expect { indexer.map_record('date_made_early' => '1539', 'date_made_late' => '2050') }.to raise_error(StandardError, exp_err_msg)
      end
    end

    it 'when one date is empty, range is a single year' do
      expect(indexer.map_record('date_made_early' => '300')).to include 'range' => [300]
      expect(indexer.map_record('date_made_late' => '666')).to include 'range' => [666]
    end

    it 'when both dates are empty, no error is raised' do
      expect(indexer.map_record({})).to eq({})
    end

    it 'date strings with no numbers are interpreted as missing' do
      expect(indexer.map_record('date_made_early' => 'not_a_number', 'date_made_late' => 'me_too')).to eq({})
    end

    it 'date strings with text and numbers are interpreted as 0' do
      expect(indexer.map_record('date_made_early' => 'not999', 'date_made_late' => 'year of 1939')).to include 'range' => [0]
    end
  end
end
