class VACOLS::Case < VACOLS::Record
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

  DISPOSITIONS = {
    "1" => "Allowed",
    "3" => "Remanded",
    "4" => "Denied",
    "5" => "Vacated",
    "6" => "Dismissed, Other",
    "8" => "Dismissed, Death",
    "9" => "Withdrawn",
    "A" => "Advance Allowed in Field",
    "B" => "Benefits Granted by AOJ",
    "D" => "Designation of Record",
    "E" => "Advance Withdrawn Death of Veteran",
    "F" => "Advance Withdrawn by Appellant/Rep",
    "G" => "Advance Failure to Respond",
    "L" => "Manlincon Remand",
    "M" => "Merged Appeal",
    "Q" => "Recon Motion Withdrawn",
    "R" => "Reconsideration by Letter",
    "V" => "Motion to Vacate Withdrawn",
    "W" => "Withdrawn from Remand",
    "X" => "Remand Failure to Respond"
  }.freeze

  STATUS = {
    "ACT" => "Active", # Case currently at BVA
    "ADV" => "Advance", # NOD Filed. Case currently at RO
    "REM" => "Remand", # Case has been Remanded to RO or AMC
    "HIS" => "Complete", # BVA action is complete
    "MOT" => "Motion" # appellant has filed a motion for reconsideration
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

  JOIN_ISSUE_CNT_REMAND = "
    inner join
    (
      select ISSKEY,
      count(case when ISSDC = '3' then 1 end) ISSUE_CNT_REMAND

      from ISSUES
      group by ISSKEY
    )
    on ISSKEY = BFKEY
  ".freeze

  WHERE_PAPERLESS_REMAND_LOC97 = "
    BFMPRO = 'REM'
    -- Remand status.

    and BFCURLOC = '97'
    -- Currently sitting in loc 97.

    and TIVBMS = 'Y'
    -- Only include VBMS cases.
  ".freeze

  WHERE_PAPERLESS_NONPA_FULLGRANT_AFTER_DATE = %{
    BFDC = '1'
    -- Cases marked with the disposition Allowed, which have at least one grant.

    and BFDDEC >= to_date(?, 'YYYY-MM-DD HH24:MI')
    -- As all full grants are in HIS status, we must time bracket our requests.

    and TIVBMS = 'Y'
    -- Only include VBMS cases.

    and BFSO <> 'T'
    -- Exclude cases with a private attorney.

    and ISSUE_CNT_REMAND = 0
    -- Check that there are no remands on the case. Denials can be included.
  }.freeze

  # These scopes query VACOLS and cannot be covered by automated tests.
  # :nocov:
  def self.remands_ready_for_claims_establishment
    VACOLS::Case.joins(:folder, :correspondent)
                .where(WHERE_PAPERLESS_REMAND_LOC97)
                .order("BFDDEC ASC")
  end

  def self.amc_full_grants(decided_after:)
    VACOLS::Case.joins(:folder, :correspondent, JOIN_ISSUE_CNT_REMAND)
                .where(WHERE_PAPERLESS_NONPA_FULLGRANT_AFTER_DATE, decided_after.strftime("%Y-%m-%d %H:%M"))
                .order("BFDDEC ASC")
  end

  def update_vacols_location(location)
    return unless location
    user_db_id = RequestStore.store[:current_user].regional_office.upcase

    self.class.transaction do
      self.class.connection.execute(<<-EOQ)
        UPDATE BRIEFF
        SET BFDLOCIN = SYSDATE,
            BFCURLOC = #{location},
            BFDLOOUT = SYSDATE,
            BFORGTIC = NULL
        WHERE BFKEY = #{bfkey};
      EOQ

      self.class.connection.execute(<<-EOQ)
        UPDATE PRIORLOC
        SET LOCDIN = SYSDATE,
            LOCSTRCV = #{user_db_id},
            LOCEXCEP = 'Y'
        WHERE LOCKEY = #{bfkey} and LOCDIN is NULL;
      EOQ

      self.class.connection.execute(<<-EOQ)
        INSERT into PRIORLOC
          (LOCDOUT, LOCDTO, LOCSTTO, LOCSTOUT, LOCKEY)
        VALUES
         (SYSDATE, SYSDATE, #{bfkey}, #{user_db_id}, :in_folder)
        USING SQLCA;
      EOQ
    end
  end
  # :nocov:
end
