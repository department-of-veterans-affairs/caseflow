class VACOLS::Case < VACOLS::Record
  self.table_name = "vacols.brieff"
  self.sequence_name = "vacols.bfkeyseq"
  self.primary_key = "bfkey"

  has_one    :folder,          foreign_key: :ticknum
  has_one    :representative,  foreign_key: :repkey
  belongs_to :correspondent,   foreign_key: :bfcorkey, primary_key: :stafkey
  has_many   :case_issues,     foreign_key: :isskey
  has_many   :notes,           foreign_key: :tsktknm
  has_many   :case_hearings,   foreign_key: :folder_nr

  class InvalidLocationError < StandardError; end

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
    "P" => "RAMP Opt-in",
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

  # corresponds to BRIEFF.bfso
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
    # TODO: double check that "Other Service Organization" is the correct full name.
    # Possibly this should just be "Other"
    "O" => { full_name: "Other Service Organization", short: "Other", rep_name_in_rep_table: true },
    "P" => { full_name: "Army & Air Force Mutual Aid Assn.", short: "Army Mut Aid" },
    "Q" => { full_name: "Catholic War Veterans", short: "Catholic War Vets" },
    "R" => { full_name: "Fleet Reserve Association", short: "Fleet Reserve" },
    "S" => { full_name: "Marine Corp League", short: "Marine Corps League" },
    "T" => { full_name: "Attorney", short: "Attorney", rep_name_in_rep_table: true },
    "U" => { full_name: "Agent", short: "Agent", rep_name_in_rep_table: true },
    "V" => { full_name: "Vietnam Veterans of America", short: "VVA" },
    "W" => { full_name: "One Time Representative", short: "One Time Rep", rep_name_in_rep_table: true },
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

  HEARING_REQUEST_TYPES = {
    "1" => :central_office,
    "2" => :travel_board,
    "3" => :confirmation_needed,
    "4" => :clarification_needed,
    "5" => :none
  }.freeze

  HEARING_PREFERENCE_TYPES_V2 = {
    VIDEO: { vacols_value: "2", video_hearing: true, ready_for_hearing: true },
    TRAVEL_BOARD: { vacols_value: "2", ready_for_hearing: true },
    WASHINGTON_DC: { vacols_value: "1" },
    # when the hearing type is not specified,
    # default to a video hearing.
    HEARING_TYPE_NOT_SPECIFIED: { vacols_value: "2", video_hearing: true, ready_for_hearing: true },
    NO_HEARING_DESIRED: { vacols_value: "5" },
    HEARING_CANCELLED: { vacols_value: "5" },
    NO_BOX_SELECTED: { vacols_value: "5" }
  }.freeze

  # NOTE(jd): This is a list of the valid locations that Caseflow
  # supports updating an appeal to. This is a subset of the overall locations
  # supported in VACOLS
  VALID_UPDATE_LOCATIONS = %w(50 51 53 54 77 98 99).freeze

  JOIN_ISSUE_COUNT = "
    inner join
    (
      select ISSKEY,

      count(case when ISSDC = '3' then 1 end) ISSUE_CNT_REMAND,
      count(case when
      (
        ISSDC = '1' and not
          (
            ISSPROG = '02' and
            ISSCODE = '15' and
            ISSLEV1 = '04'
          )
        )
        then 1 end) ISSUE_CNT_ALLOWED

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

  WHERE_PAPERLESS_FULLGRANT_AFTER_DATE = %{
    BFMPRO = 'HIS'

    and TIOCTIME >= to_date(?, 'YYYY-MM-DD HH24:MI')
    -- As all full grants are in HIS status, we must time bracket our requests.

    and TIVBMS = 'Y'
    -- Only include VBMS cases.

    and ISSUE_CNT_ALLOWED > 0
    -- Check that there is at least one non-new-material allowed issue

    and ISSUE_CNT_REMAND = 0
    -- Check that there are no remanded issues. Denials can be included.
  }.freeze

  # These scopes query VACOLS and cannot be covered by automated tests.
  # :nocov:
  def self.remands_ready_for_claims_establishment
    VACOLS::Case.joins(:folder, :correspondent)
                .where(WHERE_PAPERLESS_REMAND_LOC97)
                .order("BFDDEC ASC")
  end

  def self.amc_full_grants(outcoded_after:)
    if FeatureToggle.enabled?(:dispatch_full_grants_with_pa)
      VACOLS::Case.joins(:folder, :correspondent, JOIN_ISSUE_COUNT)
                  .where(WHERE_PAPERLESS_FULLGRANT_AFTER_DATE, outcoded_after.to_formatted_s(:oracle_date))
                  .order("BFDDEC ASC")
    else
      VACOLS::Case.joins(:folder, :correspondent, JOIN_ISSUE_COUNT)
                  .where(WHERE_PAPERLESS_FULLGRANT_AFTER_DATE, outcoded_after.to_formatted_s(:oracle_date))
                  .where(%(BFSO <> 'T'))
                  .order("BFDDEC ASC")
    end
  end

  # rubocop:disable Metrics/MethodLength
  def update_vacols_location!(location)
    return unless location

    fail(InvalidLocationError) unless VALID_UPDATE_LOCATIONS.include?(location)

    conn = self.class.connection

    # Note: we use conn.quote here from ActiveRecord to deter SQL injection
    location = conn.quote(location)
    user_db_id = conn.quote(RequestStore.store[:current_user].regional_office.upcase)
    case_id = conn.quote(bfkey)

    MetricsService.record("VACOLS: update_vacols_location! #{bfkey}",
                          service: :vacols,
                          name: "update_vacols_location") do
      conn.transaction do
        conn.execute(<<-SQL)
          UPDATE BRIEFF
          SET BFDLOCIN = SYSDATE,
              BFCURLOC = #{location},
              BFDLOOUT = SYSDATE,
              BFORGTIC = NULL
          WHERE BFKEY = #{case_id}
        SQL

        conn.execute(<<-SQL)
          UPDATE PRIORLOC
          SET LOCDIN = SYSDATE,
              LOCSTRCV = #{user_db_id},
              LOCEXCEP = 'Y'
          WHERE LOCKEY = #{case_id} and LOCDIN is NULL
        SQL

        conn.execute(<<-SQL)
          INSERT into PRIORLOC
            (LOCDOUT, LOCDTO, LOCSTTO, LOCSTOUT, LOCKEY)
          VALUES
           (SYSDATE, SYSDATE, #{location}, #{user_db_id}, #{case_id})
        SQL
      end
    end
  end

  ##
  # This method takes an array of vacols ids and fetches their aod status.
  #
  def self.aod(vacols_ids)
    conn = connection

    conn.transaction do
      query = <<-SQL
        SELECT BRIEFF.BFKEY, (case when (nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0)) > 0 then 1 else 0 end) AOD
        FROM BRIEFF

        LEFT JOIN (
          SELECT TSKTKNM, count(*) CNT
          FROM ASSIGN
          WHERE TSKACTCD in ('B', 'B1', 'B2')
          GROUP BY TSKTKNM
        ) AOD_DIARIES
        ON AOD_DIARIES.TSKTKNM = BRIEFF.BFKEY
        LEFT JOIN (
          SELECT FOLDER_NR, count(*) CNT
          FROM HEARSCHED
          WHERE HEARING_TYPE IN ('C', 'T', 'V')
            AND AOD IN ('G', 'Y')
          GROUP BY FOLDER_NR
        ) AOD_HEARINGS
        ON AOD_HEARINGS.FOLDER_NR = BRIEFF.BFKEY
        WHERE BRIEFF.BFKEY IN (?)
      SQL

      aod_result = MetricsService.record("VACOLS: Case.aod for #{vacols_ids}", name: "Case.aod",
                                                                               service: :vacols) do
        conn.exec_query(sanitize_sql_array([query, vacols_ids]))
      end

      aod_result.to_hash.reduce({}) do |memo, result|
        memo[(result["bfkey"]).to_s] = (result["aod"] == 1)
        memo
      end
    end
  end

  # :nocov:
end
