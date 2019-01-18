# rubocop:disable Metrics/ClassLength
class RegionalOffice
  class NotFoundError < StandardError; end

  MULTIPLE_ROOM_ROS = %w[RO17 RO18].freeze
  MULTIPLE_NUM_OF_RO_ROOMS = 2
  DEFAULT_NUM_OF_RO_ROOMS = 1

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
    "283" => "DSUSER",
    "499" => "NWQ"
  }.freeze

  CITIES = {
    "RO01" =>
    { label: "Boston regional office",
      city: "Boston",
      state: "MA",
      timezone: "America/New_York",
      hold_hearings: true,
      facility_locator_id: "vba_301",
      alternate_locations: nil },
    "RO02" =>
  { label: "Togus regional office",
    city: "Togus",
    state: "ME",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_402",
    alternate_locations: %w[vha_402GA vha_402HB] },
    "RO03" =>
  { label: "White River regional office",
    city: "White River Foreign Cases",
    state: "VT",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: "vba_405",
    alternate_locations: nil },
    "RO04" =>
  { label: "Providence regional office",
    city: "Providence",
    state: "RI",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_304",
    alternate_locations: nil },
    "RO05" =>
  { label: "White River regional office",
    city: "White River Junction",
    state: "VT",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_405",
    alternate_locations: nil },
    "RO06" =>
  { label: "New York City regional office",
    city: "New York",
    state: "NY",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_306",
    alternate_locations: ["vba_306b"] },
    "RO07" =>
  { label: "Buffalo regional office",
    city: "Buffalo",
    state: "NY",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_307",
    alternate_locations: nil },
    "RO08" =>
  { label: "Hartford regional office",
    city: "Hartford",
    state: "CT",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_308",
    alternate_locations: nil },
    "RO09" =>
  { label: "Newark regional office",
    city: "Newark",
    state: "NJ",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_309",
    alternate_locations: nil },
    "RO10" =>
  { label: "Philadelphia regional office",
    city: "Philadelphia",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_310",
    alternate_locations: %w[vha_595 vba_460 vha_693 vha_542 vha_460HE] },
    "RO11" =>
  { label: "Pittsburgh regional office",
    city: "Pittsburgh",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_311",
    alternate_locations: nil },
    "RO13" =>
  { label: "Baltimore regional office",
    city: "Baltimore",
    state: "MD",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_313",
    alternate_locations: ["vba_372"] },
    "RO14" =>
  { label: "Roanoke regional office",
    city: "Roanoke",
    state: "VA",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_314",
    alternate_locations: ["vba_372"] },
    "C" =>
  { label: "Central",
    city: "Washington",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: "vba_372",
    alternate_locations: nil },
    "RO15" =>
  { label: "Huntington regional office",
    city: "Huntington",
    state: "WV",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_315",
    alternate_locations: nil },
    "RO16" =>
  { label: "Atlanta regional office",
    city: "Atlanta",
    state: "GA",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_316",
    alternate_locations: nil },
    "RO17" =>
  { label: "St. Petersburg regional office",
    city: "St. Petersburg",
    state: "FL",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_317",
    alternate_locations: ["vba_317a"] },
    "RO18" =>
  { label: "Winston-Salem regional office",
    city: "Winston-Salem",
    state: "NC",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_318",
    alternate_locations: nil },
    "RO19" =>
  { label: "Columbia regional office",
    city: "Columbia",
    state: "SC",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_319",
    alternate_locations: nil },
    "RO20" =>
  { label: "Nashville regional office",
    city: "Nashville",
    state: "TN",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_320",
    alternate_locations: %w[vc_0701V vc_0720V vc_0719V vha_626GF] },
    "RO21" =>
  { label: "New Orleans regional office",
    city: "New Orleans",
    state: "LA",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_321",
    alternate_locations: ["vba_321b"] },
    "RO22" =>
  { label: "Montgomery regional office",
    city: "Montgomery",
    state: "AL",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_322",
    alternate_locations: nil },
    "RO23" =>
  { label: "Jackson regional office",
    city: "Jackson",
    state: "MS",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_323",
    alternate_locations: nil },
    "RO25" =>
  { label: "Cleveland regional office",
    city: "Cleveland",
    state: "OH",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_325",
    alternate_locations: %w[vha_539 vha_757 vha_539] },
    "RO26" =>
  { label: "Indianapolis regional office",
    city: "Indianapolis",
    state: "IN",
    timezone: "America/Indiana/Indianapolis",
    hold_hearings: true,
    facility_locator_id: "vba_326",
    alternate_locations: nil },
    "RO27" =>
  { label: "Louisville regional office",
    city: "Louisville",
    state: "KY",
    timezone: "America/Kentucky/Louisville",
    hold_hearings: true,
    facility_locator_id: "vba_327",
    alternate_locations: %w[vba_315
                            vba_320
                            vha_596
                            vba_325b
                            vha_539
                            vha_657GJ
                            vha_596GC
                            vha_596GB
                            vha_596GA
                            vha_657GL
                            vha_626GJ
                            vc_0701V
                            vha_626GC
                            vha_538GB
                            vha_603GF
                            vha_596GD
                            vha_657GP
                            vha_657GO
                            vha_626GH
                            vc_0719V
                            vc_0701V
                            vc_0719V] },
    "RO28" =>
  { label: "Chicago regional office",
    city: "Chicago",
    state: "IL",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_328",
    alternate_locations: ["vha_636GF"] },
    "RO29" =>
  { label: "Detroit regional office",
    city: "Detroit",
    state: "MI",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_329",
    alternate_locations: nil },
    "RO30" =>
  { label: "Milwaukee regional office",
    city: "Milwaukee",
    state: "WI",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_330",
    alternate_locations: %w[vba_335
                            vha_607
                            vha_676
                            vha_585
                            vha_676GA
                            vha_618GM
                            vha_676GD
                            vha_676GC
                            vha_607GE
                            vha_607GD
                            vha_607GC
                            vha_695GD
                            vha_695GA
                            vha_695BY
                            vha_618BY
                            vha_676GE
                            vha_556GD
                            vha_618GH
                            vha_585GC
                            vha_618GE] },
    "RO31" =>
  { label: "St. Louis regional office",
    city: "St. Louis",
    state: "MO",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_331",
    alternate_locations: nil },
    "RO33" =>
  { label: "Des Moines regional office",
    city: "Des Moines",
    state: "IA",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_333",
    alternate_locations: %w[vha_636GF
                            vha_438GC
                            vha_636GJ
                            vha_636GD
                            vha_438GA
                            vha_636GH
                            vha_636] },
    "RO34" =>
  { label: "Lincoln regional office",
    city: "Lincoln",
    state: "NE",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_334",
    alternate_locations: ["vba_442"] },
    "RO35" =>
  { label: "St. Paul regional office",
    city: "St. Paul",
    state: "MN",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_335",
    alternate_locations: nil },
    "RO36" =>
  { label: "Ft. Harrison regional office",
    city: "Ft. Harrison",
    state: "MT",
    timezone: "America/Denver",
    hold_hearings: true,
    facility_locator_id: "vba_436",
    alternate_locations: nil },
    "RO37" =>
  { label: "Fargo regional office",
    city: "Fargo",
    state: "ND",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_437",
    alternate_locations: nil },
    "RO38" =>
  { label: "Sioux Falls regional office",
    city: "Sioux Falls",
    state: "SD",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_438",
    alternate_locations: %w[vha_568 vha_568A4] },
    "RO39" =>
  { label: "Denver regional office",
    city: "Denver",
    state: "CO",
    timezone: "America/Denver",
    hold_hearings: true,
    facility_locator_id: "vba_339",
    alternate_locations: nil },
    "RO40" =>
  { label: "Albuquerque regional office",
    city: "Albuquerque",
    state: "NM",
    timezone: "America/Denver",
    hold_hearings: true,
    facility_locator_id: "vba_340",
    alternate_locations: nil },
    "RO41" =>
  { label: "Salt Lake City regional office",
    city: "Salt Lake City",
    state: "UT",
    timezone: "America/Denver",
    hold_hearings: true,
    facility_locator_id: "vba_341",
    alternate_locations: nil },
    "RO42" =>
  { label: "Cheyenne regional office",
    city: "Cheyenne",
    state: "WY",
    timezone: "America/Denver",
    hold_hearings: true,
    facility_locator_id: "vba_442",
    alternate_locations: ["vha_666GB"] },
    "RO43" =>
  { label: "Oakland regional office",
    city: "Oakland",
    state: "CA",
    timezone: "America/Los_Angeles",
    hold_hearings: true,
    facility_locator_id: "vba_343",
    alternate_locations: ["vba_343an"] },
    "RO44" =>
  { label: "Los Angeles regional office",
    city: "Los Angeles",
    state: "CA",
    timezone: "America/Los_Angeles",
    hold_hearings: true,
    facility_locator_id: "vba_344",
    alternate_locations: nil },
    "RO45" =>
  { label: "Phoenix regional office",
    city: "Phoenix",
    state: "AZ",
    timezone: "America/Denver",
    hold_hearings: true,
    facility_locator_id: "vba_345",
    alternate_locations: nil },
    "RO46" =>
  { label: "Seattle regional office",
    city: "Seattle",
    state: "WA",
    timezone: "America/Los_Angeles",
    hold_hearings: true,
    facility_locator_id: "vba_346",
    alternate_locations: %w[vha_663GC
                            vha_663GE
                            vba_348
                            vha_663GD
                            vha_668
                            vha_687
                            vc_0523V] },
    "RO47" =>
  { label: "Boise regional office",
    city: "Boise",
    state: "ID",
    timezone: "America/Boise",
    hold_hearings: true,
    facility_locator_id: "vba_347",
    alternate_locations: %w[vha_668 vha_660GA vha_668GB] },
    "RO48" =>
  { label: "Portland regional office",
    city: "Portland",
    state: "OR",
    timezone: "America/Los_Angeles",
    hold_hearings: true,
    facility_locator_id: "vba_348",
    alternate_locations: %w[vba_347
                            vha_653GB
                            vha_648GA
                            vha_692GA
                            vha_687GC
                            vha_653GA
                            vha_653
                            vba_346
                            vha_692] },
    "RO49" =>
  { label: "Waco regional office",
    city: "Waco",
    state: "TX",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_349",
    alternate_locations: ["vba_349i"] },
    "RO50" =>
  { label: "Little Rock regional office",
    city: "Little Rock",
    state: "AR",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_350",
    alternate_locations: nil },
    "RO51" =>
  { label: "Muskogee regional office",
    city: "Muskogee",
    state: "OK",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_351",
    alternate_locations: nil },
    "RO52" =>
  { label: "Wichita regional office",
    city: "Wichita",
    state: "KS",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: "vba_452",
    alternate_locations: nil },
    "RO54" =>
  { label: "Reno regional office",
    city: "Reno",
    state: "NV",
    timezone: "America/Los_Angeles",
    hold_hearings: true,
    facility_locator_id: "vba_354",
    alternate_locations: ["vba_354a"] },
    "RO55" =>
  { label: "San Juan regional office",
    city: "San Juan",
    state: "PR",
    timezone: "America/Puerto_Rico",
    hold_hearings: true,
    facility_locator_id: "vba_355",
    alternate_locations: nil },
    "RO58" =>
  { label: "Manila regional office",
    city: "Manila",
    state: "PI",
    timezone: "Asia/Manila",
    hold_hearings: true,
    facility_locator_id: "vba_358",
    alternate_locations: nil },
    "RO59" =>
  { label: "Honolulu regional office",
    city: "Honolulu",
    state: "HI",
    timezone: "Pacific/Honolulu",
    hold_hearings: true,
    facility_locator_id: "vba_459",
    alternate_locations: %w[vc_0616V
                            vba_459h
                            vba_459i
                            vc_0633V
                            vc_0636V
                            vc_0634V
                            vha_459GH] },
    "RO60" =>
  { label: "Wilmington regional office",
    city: "Wilmington",
    state: "DE",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO61" =>
  { label: "Houston regional office",
    city: "Houston Foreign Cases",
    state: "TX",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: "vba_362",
    alternate_locations: %w[vha_671BY vha_740GB] },
    "RO62" =>
  { label: "Houston regional office",
    city: "Houston",
    state: "TX",
    timezone: "America/Chicago",
    hold_hearings: true,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO63" =>
  { label: "Anchorage regional office",
    city: "Anchorage",
    state: "AK",
    timezone: "America/Anchorage",
    hold_hearings: true,
    facility_locator_id: "vba_463",
    alternate_locations: nil },
    "RO64" =>
  { label: nil,
    city: "Columbia Fiduciary Hub",
    state: "SC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO65" =>
  { label: nil,
    city: "Indianapolis Fiduciary Hub",
    state: "IN",
    timezone: "America/Indiana/Indianapolis",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO66" =>
  { label: nil,
    city: "Lincoln Fiduciary Hub",
    state: "NE",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO67" =>
  { label: nil,
    city: "Louisville Fiduciary Hub",
    state: "KY",
    timezone: "America/Kentucky/Louisville",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO68" =>
  { label: nil,
    city: "Milwaukee Fiduciary Hub",
    state: "WI",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO69" =>
  { label: nil,
    city: "Western Area Fiduciary Hub",
    state: "UT",
    timezone: "America/Denver",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO70" =>
  { label: nil,
    city: "Louisville CLCW",
    state: "KY",
    timezone: "America/Kentucky/Louisville",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO71" =>
  { label: nil,
    city: "Pittsburgh Foreign Cases",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO72" =>
  { label: "Washington, DC regional office",
    city: "Washington",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO73" =>
  { label: "Manchester regional office",
    city: "Manchester",
    state: "NH",
    timezone: "America/New_York",
    hold_hearings: true,
    facility_locator_id: "vba_373",
    alternate_locations: ["vba_405"] },
    "RO74" =>
  { label: nil,
    city: "Philadelphia RACC",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO75" =>
  { label: nil,
    city: "Milwaukee RACC",
    state: "WI",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO76" =>
  { label: nil,
    city: "St. Paul RACC",
    state: "MN",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO77" =>
  { label: "San Diego regional office",
    city: "San Diego",
    state: "CA",
    timezone: "America/Los_Angeles",
    hold_hearings: true,
    facility_locator_id: "vba_377",
    alternate_locations: nil },
    "RO78" =>
  { label: "Legacy RO (RO78)",
    city: "Unknown",
    state: "??",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO79" =>
  { label: nil,
    city: "St. Paul Regional Loan Center",
    state: "MN",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO80" =>
  { label: nil,
    city: "Philadelphia Insurance Center",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO81" =>
  { label: nil,
    city: "Philadelphia Pension Center",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO82" =>
  { label: nil,
    city: "Milwaukee Pension Center",
    state: "WI",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO83" =>
  { label: nil,
    city: "St. Paul Pension Center",
    state: "MN",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO84" =>
  { label: nil,
    city: "Philadelphia COWAC",
    state: "PA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO85" =>
  { label: nil,
    city: "Milwaukee COWAC",
    state: "WI",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO86" =>
  { label: nil,
    city: "St. Paul COWAC",
    state: "MN",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO87" =>
  { label: nil,
    city: "Atlanta Health Eligibility Center",
    state: "GA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO88" =>
  { label: nil,
    city: "LGY Eligibility Center - Atlanta",
    state: "GA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO89" =>
  { label: nil,
    city: "General Counsel",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO91" =>
  { label: nil,
    city: "Buffalo Education Center",
    state: "NY",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO92" =>
  { label: nil,
    city: "Atlanta Education Center",
    state: "GA",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO93" =>
  { label: nil,
    city: "Muskogee Education Center",
    state: "OK",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO94" =>
  { label: nil,
    city: "St. Louis Education Center",
    state: "MO",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO97" =>
  { label: nil,
    city: "ARC",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO98" =>
  { label: nil,
    city: "National Cemetery Administration - St. Louis",
    state: "MO",
    timezone: "America/Chicago",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "RO99" =>
  { label: nil,
    city: "VHA CO",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "DSUSER" =>
  { label: nil,
    city: "Digital Service HQ",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "VACO" =>
  { label: nil,
    city: "Washington",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil },
    "NWQ" =>
  { label: nil,
    city: "Washington",
    state: "DC",
    timezone: "America/New_York",
    hold_hearings: false,
    facility_locator_id: nil,
    alternate_locations: nil }
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

  def self.city_state_by_key(ro_key)
    regional_office = CITIES[ro_key]
    if regional_office
      "#{regional_office[:city]}, #{regional_office[:state]}"
    end
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
    result&.first
  end

  class << self
    # Returns a regional office with the specified key,
    # throws an error if not found
    def find!(key)
      result = RegionalOffice.new(key)

      fail NotFoundError unless result.valid?

      result
    end

    def ros_with_hearings
      CITIES.select { |_key, value| value[:hold_hearings] }
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
