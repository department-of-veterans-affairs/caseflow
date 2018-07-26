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
  has_many   :decass,          foreign_key: :defolder
  has_one    :staff,           foreign_key: :slogid, primary_key: :bfcurloc
  has_many   :priorloc,        foreign_key: :lockey

  class InvalidLocationError < StandardError; end

  BVA_DISPOSITION_CODES = %w[1 3 4 5 6 8 9].freeze

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

  STATUS = {
    "ACT" => "Active", # Case currently at BVA
    "ADV" => "Advance", # NOD Filed. Case currently at RO
    "REM" => "Remand", # Case has been Remanded to RO or AMC
    "HIS" => "Complete", # BVA action is complete
    "MOT" => "Motion", # appellant has filed a motion for reconsideration
    "CAV" => "CAVC" # Case has been remanded from CAVC to BVA
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

  JOIN_AOD = "
    left join (
      select BRIEFF.BFKEY AODKEY,
        (case when (nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0)) > 0 then 1 else 0 end) AOD
      from BRIEFF

      left join (
        select TSKTKNM, count(*) CNT
        from ASSIGN
        where TSKACTCD in ('B', 'B1', 'B2')
        group by TSKTKNM
      ) AOD_DIARIES
      on AOD_DIARIES.TSKTKNM = BRIEFF.BFKEY
      left join (
        select FOLDER_NR, count(*) CNT
        from HEARSCHED
        where HEARING_TYPE IN ('C', 'T', 'V')
          AND AOD IN ('G', 'Y')
        group by FOLDER_NR
      ) AOD_HEARINGS
      on AOD_HEARINGS.FOLDER_NR = BRIEFF.BFKEY
    )
    on AODKEY = BFKEY
  ".freeze

  JOIN_REMAND_RETURN = "
    left join (
      select BRIEFF.BFKEY REM_RETURN_KEY, max(PRIORLOC.LOCDOUT) REM_RETURN
      from BRIEFF
      left join PRIORLOC
        on PRIORLOC.LOCKEY = BRIEFF.BFKEY
          and PRIORLOC.LOCSTTO = '96'
      group by BRIEFF.BFKEY
    )
    on REM_RETURN_KEY = BFKEY
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
    VACOLS::Case.joins(:folder, :correspondent, JOIN_ISSUE_COUNT)
      .where(WHERE_PAPERLESS_FULLGRANT_AFTER_DATE, outcoded_after.to_formatted_s(:oracle_date))
      .order("BFDDEC ASC")
  end

  # The attributes that are copied over when the case is cloned because of a remand
  def remand_clone_attributes
    slice(
      :bfcorkey, :bfcorlid, :bfdnod, :bfdsoc, :bfd19, :bf41stat, :bfregoff,
      :bfissnr, :bfdorg, :bfdc, :bfic, :bfio, :bfoc, :bfms, :bfsh, :bfso,
      :bfst, :bfdrodec, :bfcasev, :bfdpdcn, :bfddro, :bfdroid, :bfdrortr, :bfro1
    )
  end

  # rubocop:disable Metrics/MethodLength
  def update_vacols_location!(location)
    unless location
      Rails.logger.error "THERE IS A BUG IN YOUR CODE! It attempted to assign a case to a falsy location. " \
                         "Unfortunately, I can't throw an exception here because code may depend on this method " \
                         "failing silently. Please validate before passing it to this method."
      return
    end

    conn = self.class.connection

    # Note: we use conn.quote here from ActiveRecord to deter SQL injection
    location = conn.quote(location)

    vacols_user_id = RequestStore.store[:current_user].vacols_uniq_id || ""
    user_db_id = conn.quote(vacols_user_id.upcase)
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
  # rubocop:enable Metrics/MethodLength

  def previous_active_location
    conn = self.class.connection

    case_id = conn.quote(bfkey)

    result = MetricsService.record("VACOLS: previous_location #{bfkey}",
                                   service: :vacols,
                                   name: "previous_location") do
      conn.select_all(<<-SQL)
        SELECT LOCSTTO
        FROM PRIORLOC
        WHERE LOCKEY = #{case_id}
          AND LOCSTTO <> '99'
          AND LOCDIN IS NOT NULL
        ORDER BY LOCDOUT DESC
      SQL
    end

    result.first["locstto"]
  end

  ##
  # This method takes an array of vacols ids and fetches their aod status.
  #
  def self.aod(vacols_ids)
    aod_result = MetricsService.record("VACOLS: Case.aod for #{vacols_ids}", name: "Case.aod",
                                                                             service: :vacols) do
      VACOLS::Case.joins(JOIN_AOD).where(bfkey: vacols_ids).select("bfkey", "aod")
    end

    aod_result.reduce({}) do |memo, result|
      memo[(result["bfkey"]).to_s] = (result["aod"] == 1)
      memo
    end
  end

  def self.remand_return_date(vacols_ids)
    result = MetricsService.record("VACOLS: Case.remand_return_date for #{vacols_ids}",
                                   name: "Case.remand_return_date",
                                   service: :vacols) do
      VACOLS::Case.joins(JOIN_REMAND_RETURN).where(bfkey: vacols_ids).select("bfkey", "rem_return")
    end

    result.each_with_object({}) do |row, memo|
      memo[(row["bfkey"]).to_s] = VacolsHelper.normalize_vacols_datetime(row["rem_return"])
    end
  end

  # :nocov:
end
