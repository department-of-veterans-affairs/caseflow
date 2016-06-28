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
    "2" => { full_name: "Wounded Warrior Project", short: "WWP" },
    "3" => { full_name: nil, short: nil },
    "4" => { full_name: nil, short: nil },
    "9" => { full_name: nil, short: nil },
    ">" => { full_name: nil, short: nil },
    "?" => { full_name: nil, short: nil },
    nil => { full_name: nil, short: nil }
  }.freeze

  HEARING_TYPES = {
    "1" => :central_office,
    "2" => :travel_board,
    "6" => :video_hearing
  }.freeze
end
