# frozen_string_literal: true

class VACOLS::CaseDocket < VACOLS::Record
  # :nocov:
  self.table_name = "brieff"

  class DocketNumberCentennialLoop < StandardError; end

  LOCK_READY_APPEALS = "
    select BFCURLOC from BRIEFF
    where BRIEFF.BFMPRO = 'ACT' and BRIEFF.BFCURLOC in ('81', '83')
    for update
  "

  # Distribution should be blocked by pending mail, with the exception of:
  #
  # 02 - Congressional interest
  # 05 - Evidence or argument (because the attorney will pick this up)
  # 08 - Motion to advance on the docket
  # 13 - Status inquiry

  JOIN_MAIL_BLOCKS_DISTRIBUTION = "
    left join (
      select BRIEFF.BFKEY MAILKEY,
        (case when nvl(MAIL.CNT, 0) > 0 then 1 else 0 end) MAIL_BLOCKS_DISTRIBUTION
      from BRIEFF

      left join (
        select MLFOLDER, count(*) CNT
        from MAIL
        where MLCOMPDATE is null and MLTYPE not in ('02', '05', '08', '13')
        group by MLFOLDER
      ) MAIL
      on MAIL.MLFOLDER = BRIEFF.BFKEY
    )
    on MAILKEY = BFKEY
  "

  # Distribution should be blocked by a pending diary of one of the following types:
  #
  # EXT - Extension request
  # HCL - Hearing clarification
  # POA - Power of attorney clarification

  JOIN_DIARY_BLOCKS_DISTRIBUTION = "
    left join (
      select BRIEFF.BFKEY DIARYKEY,
        (case when nvl(DIARIES.CNT, 0) > 0 then 1 else 0 end) DIARY_BLOCKS_DISTRIBUTION
      from BRIEFF

      left join (
        select TSKTKNM, count(*) CNT
        from ASSIGN
        where TSKDCLS is null and TSKACTCD in ('EXT', 'HCL', 'POA')
        group by TSKTKNM
      ) DIARIES
      on DIARIES.TSKTKNM = BRIEFF.BFKEY
    )
    on DIARYKEY = BFKEY
  "

  SELECT_READY_APPEALS = "
    select BFKEY, BFDLOOUT, BFMPRO, BFCURLOC, BFAC, BFHINES, TINUM, TITRNUM, AOD
    from BRIEFF
    #{VACOLS::Case::JOIN_AOD}
    #{JOIN_MAIL_BLOCKS_DISTRIBUTION}
    #{JOIN_DIARY_BLOCKS_DISTRIBUTION}
    inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
    where BRIEFF.BFMPRO = 'ACT'
      and BRIEFF.BFCURLOC in ('81', '83')
      and BRIEFF.BFBOX is null
      and MAIL_BLOCKS_DISTRIBUTION = 0
      and DIARY_BLOCKS_DISTRIBUTION = 0
  "

  # Judges 000, 888, and 999 are not real judges, but rather VACOLS codes.

  JOIN_ASSOCIATED_VLJS_BY_HEARINGS = "
    left join (
      select distinct TITRNUM, TINUM,
        first_value(BOARD_MEMBER) over (partition by TITRNUM, TINUM order by HEARING_DATE desc) VLJ
      from HEARSCHED
      inner join FOLDER on FOLDER.TICKNUM = HEARSCHED.FOLDER_NR
      where HEARING_TYPE in ('C', 'T', 'V') and HEARING_DISP = 'H'
    ) VLJ_HEARINGS
      on VLJ_HEARINGS.VLJ not in ('000', '888', '999')
        and VLJ_HEARINGS.TITRNUM = BRIEFF.TITRNUM
        and (VLJ_HEARINGS.TINUM is null or VLJ_HEARINGS.TINUM = BRIEFF.TINUM)
  "

  JOIN_ASSOCIATED_VLJS_BY_PRIOR_DECISIONS = "
    left join (
      select distinct TITRNUM, TINUM,
        first_value(BFMEMID) over (partition by TITRNUM, TINUM order by BFDDEC desc) VLJ
      from BRIEFF
      inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
      where BFATTID is not null and BFMEMID not in ('000', '888', '999')
    ) VLJ_PRIORDEC
      on BRIEFF.AOD = 1
        and VLJ_HEARINGS.VLJ is null
        and VLJ_PRIORDEC.TITRNUM = BRIEFF.TITRNUM
        and (VLJ_PRIORDEC.TINUM is null or VLJ_PRIORDEC.TINUM = BRIEFF.TINUM)
  "

  # rubocop:disable Metrics/MethodLength
  def self.counts_by_priority_and_readiness
    query = <<-SQL
      select count(*) N, PRIORITY, READY
      from (
        select case when BFAC = '7' or nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0) > 0 then 1 else 0 end as PRIORITY,
          case when BFCURLOC in ('81', '83') then 1 else 0 end as READY
        from BRIEFF
        left join (
          select TSKTKNM, count(*) CNT
          from ASSIGN
          where TSKACTCD in ('B', 'B1', 'B2')
          group by TSKTKNM
        ) AOD_DIARIES on AOD_DIARIES.TSKTKNM = BFKEY
        left join (
          select FOLDER_NR, count(*) CNT
          from HEARSCHED
          where HEARING_TYPE IN ('C', 'T', 'V')
            AND AOD IN ('G', 'Y')
          group by FOLDER_NR
        ) AOD_HEARINGS on AOD_HEARINGS.FOLDER_NR = BFKEY
        where BFMPRO <> 'HIS' and BFD19 is not null
      )
      group by PRIORITY, READY
    SQL

    connection.exec_query(query).to_hash
  end
  # rubocop:enable Metrics/MethodLength

  def self.nod_count
    where("BFMPRO = 'ADV' and BFD19 is null").count
  end

  def self.regular_non_aod_docket_count
    joins(VACOLS::Case::JOIN_AOD)
      .where("BFMPRO <> 'HIS' and BFAC in ('1', '3') and BFD19 is not null and AOD = 0")
      .count
  end

  def self.docket_date_of_nth_appeal_in_case_storage(row_number)
    query = <<-SQL
      select BFD19 from (
        select row_number() over (order by BFD19 asc) as ROWNUMBER,
          BFD19
        from BRIEFF
        where BFCURLOC in ('81', '83')
          and BFAC <> '9'
      )
      cross join (select count(*) as MAX_ROWNUMBER from BRIEFF where BFCURLOC in ('81', '83') and BFAC <> '9')
      where ROWNUMBER = least(?, MAX_ROWNUMBER)
    SQL

    connection.exec_query(sanitize_sql_array([query, row_number])).first["bfd19"].to_date
  end

  # rubocop:disable Metrics/MethodLength
  def self.docket_counts_by_month
    query = <<-SQL
      select YEAR, MONTH,
        coalesce(
          sum(N) over (order by YEAR, MONTH rows between unbounded preceding and 1 preceding),
          0
        ) CUMSUM_N,
        coalesce(
          sum(READY_N) over (order by YEAR, MONTH rows between unbounded preceding and 1 preceding),
          0
        ) CUMSUM_READY_N
      from (
        select extract(year from BFD19) YEAR, extract(month from BFD19) MONTH, count(*) N,
          count(case when BFMPRO = 'ACT' and (BFCURLOC  in ('81', '83') or SATTYID is not null) then 1 end) READY_N
        from BRIEFF
        inner join STAFF on BFCURLOC = STAFKEY
        left join (
          select TSKTKNM, count(*) CNT
          from ASSIGN
          where TSKACTCD in ('B', 'B1', 'B2')
          group by TSKTKNM
        ) AOD_DIARIES on AOD_DIARIES.TSKTKNM = BFKEY
        left join (
          select FOLDER_NR, count(*) CNT
          from HEARSCHED
          where HEARING_TYPE IN ('C', 'T', 'V')
            AND AOD IN ('G', 'Y')
          group by FOLDER_NR
        ) AOD_HEARINGS on AOD_HEARINGS.FOLDER_NR = BFKEY
        where BFMPRO <> 'HIS'
          and BFD19 is not null
          and BFAC in ('1', '3')
          and AOD_DIARIES.CNT is null
          and AOD_HEARINGS.CNT is null
        group by extract(year from BFD19), extract(month from BFD19)
      )
    SQL

    connection.exec_query(query)
  end
  # rubocop:enable Metrics/MethodLength

  def self.age_of_n_oldest_priority_appeals(num)
    conn = connection

    query = <<-SQL
      select BFKEY, BFDLOOUT, VLJ
      from (
        select BFKEY, BFDLOOUT,
          case when BFHINES is null or BFHINES <> 'GP' then nvl(VLJ_HEARINGS.VLJ, VLJ_PRIORDEC.VLJ) end VLJ
        from (
          #{SELECT_READY_APPEALS}
            and (BFAC = '7' or AOD = '1')
          order by BFDLOOUT
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_ASSOCIATED_VLJS_BY_PRIOR_DECISIONS}
      )
      where VLJ is null and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, num])

    appeals = conn.exec_query(fmtd_query).to_hash
    appeals.map { |appeal| appeal["bfdloout"] }
  end

  def self.nonpriority_decisions_per_year
    joins(VACOLS::Case::JOIN_AOD)
      .where(
        "BFDC in ('1', '3', '4') and BFDDEC >= ? and AOD = 0 and BFAC <> '7'",
        1.year.ago.to_date
      )
      .count
  end

  def self.distribute_nonpriority_appeals(judge, genpop, range, limit, dry_run = false)
    fail(DocketNumberCentennialLoop, COPY::MAX_LEGACY_DOCKET_NUMBER_ERROR_MESSAGE) if Time.zone.now.year >= 2030

    # Docket numbers begin with the two digit year. The Board of Veterans Appeals was created in 1930.
    # Although there are no new legacy appeals after 2019, an old appeal can be reopened through a finding
    # of clear and unmistakable error, which would result in a brand new docket number being assigned.
    # An updated docket number format will need to be in place for legacy appeals by 2030 in order
    # to ensure that docket numbers are sorted correctly.

    conn = connection

    query = <<-SQL
      select BFKEY, BFDLOOUT, VLJ, DOCKET_INDEX
      from (
        select BFKEY, BFDLOOUT, rownum DOCKET_INDEX,
          case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS.VLJ end VLJ
        from (
          #{SELECT_READY_APPEALS}
            and BFAC <> '7' and AOD = '0'
          order by case when substr(TINUM, 1, 2) between '00' and '29' then 1 else 0 end, TINUM
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      )
      where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and (DOCKET_INDEX <= ? or 1 = ?)
        and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                      (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                      range,
                                      range.nil? ? 1 : 0,
                                      limit
                                    ])

    conn.transaction do
      if dry_run
        conn.exec_query(fmtd_query).to_hash
      else
        conn.execute(LOCK_READY_APPEALS)
        appeals = conn.exec_query(fmtd_query).to_hash
        vacols_ids = appeals.map { |appeal| appeal["bfkey"] }
        location = if FeatureToggle.enabled?(:legacy_das_deprecation, user: RequestStore.store[:current_user])
                     LegacyAppeal::LOCATION_CODES[:caseflow]
                   else
                     judge.vacols_uniq_id
                   end
        VACOLS::Case.batch_update_vacols_location(location, vacols_ids)
        appeals
      end
    end
  end

  def self.distribute_priority_appeals(judge, genpop, limit, dry_run = false)
    conn = connection

    query = <<-SQL
      select BFKEY, BFDLOOUT, VLJ
      from (
        select BFKEY, BFDLOOUT,
          case when BFHINES is null or BFHINES <> 'GP' then nvl(VLJ_HEARINGS.VLJ, VLJ_PRIORDEC.VLJ) end VLJ
        from (
          #{SELECT_READY_APPEALS}
            and (BFAC = '7' or AOD = '1')
          order by BFDLOOUT
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_ASSOCIATED_VLJS_BY_PRIOR_DECISIONS}
      )
      where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                      (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                      limit
                                    ])

    conn.transaction do
      if dry_run
        conn.exec_query(fmtd_query).to_hash
      else
        conn.execute(LOCK_READY_APPEALS)
        appeals = conn.exec_query(fmtd_query).to_hash
        return appeals if appeals.empty?

        vacols_ids = appeals.map { |appeal| appeal["bfkey"] }
        location = if FeatureToggle.enabled?(:legacy_das_deprecation, user: RequestStore.store[:current_user])
                     LegacyAppeal::LOCATION_CODES[:caseflow]
                   else
                     judge.vacols_uniq_id
                   end
        VACOLS::Case.batch_update_vacols_location(location, vacols_ids)
        appeals
      end
    end
  end

  # :nocov:
end
