# rubocop:disable Metrics/ClassLength
class RegionalOffice
  class NotFoundError < StandardError; end

  # Maps CSS Station # to RO id
  STATIONS = {
    "101" => "VACO",
    "301" => "RO01",
    "402" => "RO02",
    "304" => "RO04",
    "405" => %w[RO05 RO03],
    "306" => "RO06",
    "307" => %w[RO07 RO91],
    "308" => "RO08",
    "309" => "RO09",
    "310" => %w[RO10 RO74 RO80 RO81 RO84],
    "311" => %w[RO11 RO71],
    "313" => "RO13",
    "314" => "RO14",
    "315" => "RO15",
    "316" => %w[RO16 RO87 RO92],
    "317" => "RO17",
    "318" => %w[RO18 RO88],
    "319" => "RO19",
    "320" => "RO20",
    "321" => "RO21",
    "322" => "RO22",
    "323" => "RO23",
    "325" => "RO25",
    "326" => "RO26",
    "327" => %w[RO27 RO70],
    "328" => "RO28",
    "329" => "RO29",
    "330" => %w[RO30 RO75 RO82 RO85],
    "331" => "RO31",
    "333" => "RO33",
    "334" => "RO34",
    "335" => %w[RO35 RO76 RO83],
    "436" => "RO36",
    "437" => "RO37",
    "438" => "RO38",
    "339" => "RO39",
    "340" => "RO40",
    "341" => "RO41",
    "442" => "RO42",
    "343" => "RO43",
    "344" => "RO44",
    "345" => "RO45",
    "346" => "RO46",
    "347" => "RO47",
    "348" => "RO48",
    "349" => "RO49",
    "350" => "RO50",
    "351" => %w[RO51 RO93 RO94],
    "452" => "RO52",
    "354" => "RO54",
    "355" => "RO55",
    "358" => "RO58",
    "459" => "RO59",
    "460" => "RO60",
    "362" => "RO62",
    "463" => "RO63",
    "372" => "RO72",
    "373" => "RO73",
    "377" => "RO77",
    "397" => "RO97",
    "283" => "DSUSER"
  }.freeze

  CITIES = {
    "RO01" => {
      label: "Boston regional office",
      city: "Boston", state: "MA",
      timezone: "America/New_York"
    },
    "RO02" => {
      label: "Togus regional office",
      city: "Togus", state: "ME",
      timezone: "America/New_York"
    },
    "RO03" => {
      label: "White River regional office",
      city: "White River Foreign Cases", state: "VT",
      timezone: "America/New_York"
    },
    "RO04" => {
      label: "Providence regional office",
      city: "Providence", state: "RI",
      timezone: "America/New_York"
    },
    "RO05" => {
      label: "White River regional office",
      city: "White River Junction", state: "VT",
      timezone: "America/New_York"
    },
    "RO06" => {
      label: "New York City regional office",
      city: "New York", state: "NY",
      timezone: "America/New_York"
    },
    "RO07" => {
      label: "Buffalo regional office",
      city: "Buffalo", state: "NY",
      timezone: "America/New_York"
    },
    "RO08" => {
      label: "Hartford regional office",
      city: "Hartford", state: "CT",
      timezone: "America/New_York"
    },
    "RO09" => {
      label: "Newark regional office",
      city: "Newark", state: "NJ",
      timezone: "America/New_York"
    },
    "RO10" => {
      label: "Philadelphia regional office",
      city: "Philadelphia", state: "PA",
      timezone: "America/New_York"
    },
    "RO11" => {
      label: "Pittsburgh regional office",
      city: "Pittsburgh", state: "PA",
      timezone: "America/New_York"
    },
    "RO13" => {
      label: "Baltimore regional office",
      city: "Baltimore", state: "MD",
      timezone: "America/New_York"
    },
    "RO14" => {
      label: "Roanoke regional office",
      city: "Roanoke", state: "VA",
      timezone: "America/New_York"
    },
    "RO15" => {
      label: "Huntington regional office",
      city: "Huntington", state: "WV",
      timezone: "America/New_York"
    },
    "RO16" => {
      label: "Atlanta regional office",
      city: "Atlanta", state: "GA",
      timezone: "America/New_York"
    },
    "RO17" => {
      label: "St. Petersburg regional office",
      city: "St. Petersburg", state: "FL",
      timezone: "America/New_York"
    },
    "RO18" => {
      label: "Winston-Salem regional office",
      city: "Winston-Salem", state: "NC",
      timezone: "America/New_York"
    },
    "RO19" => {
      label: "Columbia regional office",
      city: "Columbia", state: "SC",
      timezone: "America/New_York"
    },
    "RO20" => {
      label: "Nashville regional office",
      city: "Nashville", state: "TN",
      timezone: "America/Chicago"
    },
    "RO21" => {
      label: "New Orleans regional office",
      city: "New Orleans", state: "LA",
      timezone: "America/Chicago"
    },
    "RO22" => {
      label: "Montgomery regional office",
      city: "Montgomery", state: "AL",
      timezone: "America/Chicago"
    },
    "RO23" => {
      label: "Jackson regional office",
      city: "Jackson", state: "MS",
      timezone: "America/Chicago"
    },
    "RO25" => {
      label: "Cleveland regional office",
      city: "Cleveland", state: "OH",
      timezone: "America/New_York"
    },
    "RO26" => {
      label: "Indianapolis regional office",
      city: "Indianapolis", state: "IN",
      timezone: "America/Indiana/Indianapolis"
    },
    "RO27" => {
      label: "Louisville regional office",
      city: "Louisville", state: "KY",
      timezone: "America/Kentucky/Louisville"
    },
    "RO28" => {
      label: "Chicago regional office",
      city: "Chicago", state: "IL",
      timezone: "America/Chicago"
    },
    "RO29" => {
      label: "Detroit regional office",
      city: "Detroit", state: "MI",
      timezone: "America/New_York"
    },
    "RO30" => {
      label: "Milwaukee regional office",
      city: "Milwaukee", state: "WI",
      timezone: "America/Chicago"
    },
    "RO31" => {
      label: "St. Louis regional office",
      city: "St. Louis", state: "MO",
      timezone: "America/Chicago"
    },
    "RO33" => {
      label: "Des Moines regional office",
      city: "Des Moines", state: "IA",
      timezone: "America/Chicago"
    },
    "RO34" => {
      label: "Lincoln regional office",
      city: "Lincoln", state: "NE",
      timezone: "America/Chicago"
    },
    "RO35" => {
      label: "St. Paul regional office",
      city: "St. Paul", state: "MN",
      timezone: "America/Chicago"
    },
    "RO36" => {
      label: "Ft. Harrison regional office",
      city: "Ft. Harrison", state: "MT",
      timezone: "America/Denver"
    },
    "RO37" => {
      label: "Fargo regional office",
      city: "Fargo", state: "ND",
      timezone: "America/Chicago"
    },
    "RO38" => {
      label: "Sioux Falls regional office",
      city: "Sioux Falls", state: "SD",
      timezone: "America/Chicago"
    },
    "RO39" => {
      label: "Denver regional office",
      city: "Denver", state: "CO",
      timezone: "America/Denver"
    },
    "RO40" => {
      label: "Albuquerque regional office",
      city: "Albuquerque", state: "NM",
      timezone: "America/Chicago"
    },
    "RO41" => {
      label: "Salt Lake City regional office",
      city: "Salt Lake City", state: "UT",
      timezone: "America/Denver"
    },
    "RO42" => {
      label: "Cheyenne regional office",
      city: "Cheyenne", state: "WY",
      timezone: "America/Denver"
    },
    "RO43" => {
      label: "Oakland regional office",
      city: "Oakland", state: "CA",
      timezone: "America/Los_Angeles"
    },
    "RO44" => {
      label: "Los Angeles regional office",
      city: "Los Angeles", state: "CA",
      timezone: "America/Los_Angeles"
    },
    "RO45" => {
      label: "Phoenix regional office",
      city: "Phoenix", state: "AZ",
      timezone: "America/Denver"
    },
    "RO46" => {
      label: "Seattle regional office",
      city: "Seattle", state: "WA",
      timezone: "America/Los_Angeles"
    },
    "RO47" => {
      label: "Boise regional office",
      city: "Boise", state: "ID",
      timezone: "America/Boise"
    },
    "RO48" => {
      label: "Portland regional office",
      city: "Portland", state: "OR",
      timezone: "America/Los_Angeles"
    },
    "RO49" => {
      label: "Waco regional office",
      city: "Waco", state: "TX",
      timezone: "America/Chicago"
    },
    "RO50" => {
      label: "Little Rock regional office",
      city: "Little Rock", state: "AR",
      timezone: "America/Chicago"
    },
    "RO51" => {
      label: "Muskogee regional office",
      city: "Muskogee", state: "OK",
      timezone: "America/Chicago"
    },
    "RO52" => {
      label: "Wichita regional office",
      city: "Wichita", state: "KS",
      timezone: "America/Chicago"
    },
    "RO54" => {
      label: "Reno regional office",
      city: "Reno", state: "NV",
      timezone: "America/Los_Angeles"
    },
    "RO55" => {
      label: "San Juan regional office",
      city: "San Juan", state: "PR",
      timezone: "America/Puerto_Rico"
    },
    "RO58" => {
      label: "Manila regional office",
      city: "Manila", state: "PI",
      timezone: "Asia/Manila"
    },
    "RO59" => {
      label: "Honolulu regional office",
      city: "Honolulu", state: "HI",
      timezone: "Pacific/Honolulu"
    },
    "RO60" => {
      label: "Wilmington regional office",
      city: "Wilmington", state: "DE",
      timezone: "America/New_York"
    },
    "RO61" => {
      label: "Houston regional office",
      city: "Houston Foreign Cases", state: "TX",
      timezone: "America/Chicago"
    },
    "RO62" => {
      label: "Houston regional office",
      city: "Houston", state: "TX",
      timezone: "America/Chicago"
    },
    "RO63" => {
      label: "Anchorage regional office",
      city: "Anchorage", state: "AK",
      timezone: "America/Anchorage"
    },
    "RO64" => { city: "Columbia Fiduciary Hub", state: "SC", timezone: "America/New_York" },
    "RO65" => { city: "Indianapolis Fiduciary Hub", state: "IN", timezone: "America/Indiana/Indianapolis" },
    "RO66" => { city: "Lincoln Fiduciary Hub", state: "NE", timezone: "America/Chicago" },
    "RO67" => { city: "Louisville Fiduciary Hub", state: "KY", timezone: "America/Kentucky/Louisville" },
    "RO68" => { city: "Milwaukee Fiduciary Hub", state: "WI", timezone: "America/Chicago" },
    "RO69" => { city: "Western Area Fiduciary Hub", state: "UT", timezone: "America/Denver" },
    "RO70" => { city: "Louisville CLCW", state: "KY", timezone: "America/Kentucky/Louisville" },
    "RO71" => { city: "Pittsburgh Foreign Cases", state: "PA", timezone: "America/New_York" },
    "RO72" => {
      label: "Washington, DC regional office",
      city: "Washington", state: "DC",
      timezone: "America/New_York"
    },
    "RO73" => {
      label: "Manchester regional office",
      city: "Manchester", state: "NH",
      timezone: "America/New_York"
    },
    "RO74" => { city: "Philadelphia RACC", state: "PA", timezone: "America/New_York" },
    "RO75" => { city: "Milwaukee RACC", state: "WI", timezone: "America/Chicago" },
    "RO76" => { city: "St. Paul RACC", state: "MN", timezone: "America/Chicago" },
    "RO77" => {
      label: "San Diego regional office",
      city: "San Diego", state: "CA",
      timezone: "America/Los_Angeles"
    },
    "RO79" => { city: "St. Paul Regional Loan Center", state: "MN", timezone: "America/Chicago" },
    "RO80" => { city: "Philadelphia Insurance Center", state: "PA", timezone: "America/New_York" },
    "RO81" => { city: "Philadelphia Pension Center", state: "PA", timezone: "America/New_York" },
    "RO82" => { city: "Milwaukee Pension Center", state: "WI", timezone: "America/Chicago" },
    "RO83" => { city: "St. Paul Pension Center", state: "MN", timezone: "America/Chicago" },
    "RO84" => { city: "Philadelphia COWAC", state: "PA", timezone: "America/New_York" },
    "RO85" => { city: "Milwaukee COWAC", state: "WI", timezone: "America/Chicago" },
    "RO86" => { city: "St. Paul COWAC", state: "MN", timezone: "America/Chicago" },
    "RO87" => { city: "Atlanta Health Eligibility Center", state: "GA", timezone: "America/New_York" },
    "RO88" => { city: "LGY Eligibility Center - Atlanta", state: "GA", timezone: "America/New_York" },
    "RO89" => { city: "General Counsel", state: "DC", timezone: "America/New_York" },
    "RO91" => { city: "Buffalo Education Center", state: "NY", timezone: "America/New_York" },
    "RO92" => { city: "Atlanta Education Center", state: "GA", timezone: "America/New_York" },
    "RO93" => { city: "Muskogee Education Center", state: "OK", timezone: "America/Chicago" },
    "RO94" => { city: "St. Louis Education Center", state: "MO", timezone: "America/Chicago" },
    "RO97" => { city: "ARC", state: "DC", timezone: "America/New_York" },
    "RO98" => { city: "National Cemetery Administration - St. Louis", state: "MO", timezone: "America/Chicago" },
    "RO99" => { city: "VHA CO", state: "DC", timezone: "America/New_York" },
    "DSUSER" => { city: "Digital Service HQ", state: "DC", timezone: "America/New_York" },
    "VACO" => { city: "Washington", state: "DC", timezone: "America/New_York" }
  }.freeze
  ROS = CITIES.keys.freeze

  SATELLITE_OFFICES = {
    "SO62" => {
      label: "San Antonio satellite office",
      city: "San Antonio", state: "TX",
      timezone: "America/Chicago",
      regional_office: "RO62"
    },
    "SO06" => {
      label: "Albany satellite office",
      city: "Albany", state: "NY",
      timezone: "America/New_York",
      regional_office: "RO06"
    },
    "SO54" => {
      label: "Las Vegas satellite office",
      city: "Las Vegas", state: "NV",
      timezone: "America/Los_Angeles",
      regional_office: "RO54"
    },
    "SO49" => {
      label: "El Paso satellite office",
      city: "El Paso", state: "TX",
      timezone: "America/Chicago",
      regional_office: "RO49"
    },
    "SO43" => {
      label: "Sacremento satellite office",
      city: "Sacremento", state: "CA",
      timezone: "America/Los_Angeles",
      regional_office: "RO43"
    }
  }.freeze

  # The string key is a unique identifier for a regional office.
  attr_reader :key

  def initialize(key)
    @key = key
  end

  def station_key
    @station_key ||= compute_station_key
  end

  def city
    location_hash[:city]
  end

  def state
    location_hash[:state]
  end

  def to_h
    location_hash.merge(key: key)
  end

  def station_description
    "Station #{station_key} - #{city}"
  end

  def valid?
    !!location_hash[:city]
  end

  private

  def location_hash
    @location_hash ||= compute_location_hash
  end

  def compute_location_hash
    CITIES[key] || SATELLITE_OFFICES[key] || {}
  end

  def compute_station_key
    result = STATIONS.find { |_station, ros| [*ros].include? key }
    result && result.first
  end

  class << self
    # Returns a regional office with the specified key,
    # throws an error if not found
    def find!(key)
      result = RegionalOffice.new(key)

      fail NotFoundError unless result.valid?
      result
    end

    # Returns RegionalOffice objects for each RO that has the passed station code
    def for_station(station_key)
      [STATIONS[station_key]].flatten.map do |regional_office_key|
        find!(regional_office_key)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
