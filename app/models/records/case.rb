class Records::Case < ActiveRecord::Base
  self.table_name = "vacols.brieff"
  self.sequence_name = "vacols.bfkeyseq"
  self.primary_key = "bfkey"

  has_one    :folder,        foreign_key: :ticknum
  belongs_to :correspondent, foreign_key: :bfcorkey, primary_key: :stafkey

  TYPES = {
    "1" => "Original",
    "2" => "Supplemental",
    "3" => "Post Remand",
    "4" => "Reconsideration",
    "5" => "Vacate",
    "6" => "De Novo",
    "7" => "Court Remand",
    "8" => "Designation of Record",
    "9" => "Clear and Unmistakable Error"
  }.freeze

  REPRESENTATIVES = {
    "A" => { full_name: "The American Legion", short: "American Legion" },
    "B" => { full_name: "AMVETS", short: "AmVets" },
    "C" => { full_name: "American Red Cross", short: "ARC" },
    "D" => { full_name: "Disabled American Veterans", short: "DAV" },
    "E" => { full_name: "Jewish War Veterans", short: "JWV" },
    "F" => { full_name: "Military Order of the Purple Heart", short: "MOPH" },
    "G" => { full_name: "Paralyzed Veterans of America", short: "PVA" },
    "H" => { full_name: "Veterans of Foreign Wars", short: "VFW" },
    "I" => { full_name: "State Service Organization(s)", short: "State Svc Org" },
    "J" => { full_name: "Maryland Veterans Commission", short: "Md Veterans Comm" },
    "K" => { full_name: "Virginia Department of Veterans Affairs", short: "Virginia Dept of Veteran" },
    "L" => { full_name: "No Representative", short: "None" },
    "M" => { full_name: "Navy Mutual Aid Association", short: "Navy Mut Aid" },
    "N" => { full_name: "Non-Commissioned Officers Association", short: "NCOA" },
    "O" => { full_name: "Other Service Organization", short: "Other" },
    "P" => { full_name: "Army & Air Force Mutual Aid Assn.", short: "Army Mut Aid" },
    "Q" => { full_name: "Catholic War Veterans", short: "Catholic War Vets" },
    "R" => { full_name: "Fleet Reserve Association", short: "Fleet Reserve" },
    "S" => { full_name: "Marine Corp League", short: "Marine Corps League" },
    "T" => { full_name: "Attorney", short: "Attorney" },
    "U" => { full_name: "Agent", short: "Agent" },
    "V" => { full_name: "Vietnam Veterans of America", short: "VVA" },
    "W" => { full_name: "One Time Representative", short: "One Time Rep" },
    "X" => { full_name: "American Ex-Prisoners of War", short: "EXPOW" },
    "Y" => { full_name: "Blinded Veterans Association", short: "Blinded Vet Assoc" },
    "Z" => { full_name: "National Veterans Legal Services Program", short: "NVLSP" },
    "1" => { full_name: "National Veterans Organization of America", short: "NVOA" },
    nil => { full_name: nil, short: nil }
  }.freeze

  HEARING_TYPES = {
    "1" => :central_office,
    "2" => :travel_board,
    "6" => :video_hearing
  }.freeze

  ROS = {
    "RO17" => { city: "St. Petersburg", state: "FL" },
    "RO62" => { city: "Houston", state: "TX" },
    "RO49" => { city: "Waco", state: "TX" },
    "RO22" => { city: "Montgomery", state: "AL" },
    "RO16" => { city: "Atlanta", state: "GA" },
    "RO18" => { city: "Winston-Salem", state: "NC" },
    "RO39" => { city: "Denver", state: "CO" },
    "RO14" => { city: "Roanoke", state: "VA" },
    "RO25" => { city: "Cleveland", state: "OH" },
    "RO77" => { city: "San Diego", state: "CA" },
    "RO43" => { city: "Oakland", state: "CA" },
    "RO29" => { city: "Detroit", state: "MI" },
    "RO20" => { city: "Nashville", state: "TN" },
    "RO19" => { city: "Columbia", state: "SC" },
    "RO48" => { city: "Portland", state: "OR" },
    "RO46" => { city: "Seattle", state: "WA" },
    "RO51" => { city: "Muskogee", state: "OK" },
    "RO45" => { city: "Phoenix", state: "AR" },
    "RO23" => { city: "Jackson", state: "MS" },
    "RO10" => { city: "Philadelphia", state: "PA" },
    "RO28" => { city: "Chicago", state: "IL" },
    "RO44" => { city: "Los Angeles", state: "CA" },
    "RO01" => { city: "Boston", state: "MA" },
    "RO21" => { city: "New Orleans", state: "LA" },
    "RO15" => { city: "Huntington", state: "WV" },
    "RO30" => { city: "Milwaukee", state: "WI" },
    "RO31" => { city: "St. Louis", state: "MI" },
    "RO26" => { city: "Indianapolis", state: "IN" },
    "RO50" => { city: "Little Rock", state: "AR" },
    "RO06" => { city: "New York", state: "NY" },
    "RO07" => { city: "Buffalo", state: "NY" },
    "RO09" => { city: "Newark", state: "NJ" },
    "RO35" => { city: "St. Paul", state: "MN" },
    "RO34" => { city: "Lincoln", state: "NE" },
    "RO33" => { city: "Des Moines", state: "IA" },
    "RO27" => { city: "Louisville", state: "KY" },
    "RO40" => { city: "Albuquerque", state: "NM" },
    "RO55" => { city: "San Juan", state: "PR" },
    "RO04" => { city: "Providence", state: "RI" },
    "RO13" => { city: "Baltimore", state: "MD" },
    "RO47" => { city: "Boise", state: "ID" },
    "RO41" => { city: "Salt Lake City", state: "UT" },
    "RO52" => { city: "Wichita", state: "KS" },
    "RO59" => { city: "Honolulu", state: "HI" },
    "RO54" => { city: "Reno", state: "NV" },
    "RO11" => { city: "Pittsburgh", state: "PA" },
    "RO08" => { city: "Hartford", state: "CT" },
    "RO63" => { city: "Anchorage", state: "AK" },
    "RO58" => { city: "Manila", state: "PI" },
    "RO60" => { city: "Wilmington", state: "DE" },
    "RO36" => { city: "Ft. Harrison", state: "MT" },
    "RO38" => { city: "Sioux Falls", state: "SD" },
    "RO02" => { city: "Togus", state: "ME" },
    "RO73" => { city: "Manchester", state: "NH" },
    "RO37" => { city: "Fargo", state: "ND" },
    "RO05" => { city: "White River Junction", state: "VT" },
    "RO42" => { city: "Cheyenne", state: "WY" },
    "DSUSER" => { city: "Digital Service HQ", state: "DC" }
  }.freeze
end
