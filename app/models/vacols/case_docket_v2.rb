# frozen_string_literal: true

class VACOLS::CaseDocketV2 < VACOLS::Record
  # :nocov:
  self.table_name = "brieff"

  class DocketNumberCentennialLoop < StandardError; end

  HEARING_BACKLOG_LIMIT = 30

  LOCK_READY_APPEALS = "
    select BFCURLOC from BRIEFF
    where BRIEFF.BFMPRO = 'ACT' and BRIEFF.BFCURLOC in ('81', '83')
    for update
  "

  SELECT_READY_APPEALS = "
    SELECT BRIEFF.BFKEY, BRIEFF.BFCORLID, BRIEFF.BFMPRO,
      BRIEFF.BFCURLOC, BRIEFF.BFAC, BRIEFF.BFD19,
      BRIEFF.BFDLOOUT, BRIEFF.BFORGTIC, BRIEFF.BFHINES,
      FOLDER.TINUM, CORRES.SNAMEL,CORRES.SNAMEF,
      vacols_dev.prev_vlj(titrnum, tinum) VLJ_HEARINGS,
      vacols_dev.hearing_date(bfcorlid, tinum),
      vacols_dev.aod_cnt(bfkey) as AOD
    FROM BRIEFF, FOLDER, CORRES
    WHERE ( BRIEFF.BFKEY = FOLDER.TICKNUM ) and
      ( BRIEFF.BFCORKEY = CORRES.STAFKEY ) and
      ( ( bfcurloc in ('81', '83') ) AND
      ( bfmpro = 'ACT' ) AND
      ( bfd19 is not null ) AND
      ( vacols_dev.mail_cnt_loc81(bfkey) = 0 ) AND
      ( vacols_dev.diary_cnt_hold(bfkey) = 0 ) AND
      ( bfbox is null ) )
  "

  SELECT_PRIORITY_APPEALS = "
    select BFKEY, BFDLOOUT, VLJ
      from (
        select BFKEY, BFDLOOUT,
          case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS end VLJ
        from (
          #{SELECT_READY_APPEALS}
          order by BFDLOOUT
        ) BRIEFF
        where (BFAC = '7' or AOD = '1')
      )
    "

  SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19 = "
    select BFKEY, BFD19, BFDLOOUT, VLJ
      from (
        select BFKEY, BFD19, BFDLOOUT,
          case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS end VLJ
        from (
          #{SELECT_READY_APPEALS}
          order by BFDLOOUT
        ) BRIEFF
        where (BFAC = '7' or AOD = '1')
        order by BFD19
      )
    "

  SELECT_NONPRIORITY_APPEALS = "
    select BFKEY, BFDLOOUT, VLJ, DOCKET_INDEX
    from (
      select BFKEY, BFDLOOUT, rownum DOCKET_INDEX,
        case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS end VLJ
      from (
        #{SELECT_READY_APPEALS}
        order by case when substr(TINUM, 1, 2) between '00' and '29' then 1 else 0 end, TINUM
      ) BRIEFF
      where BFAC <> '7' and AOD = '0'
    )
  "

  SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19 = "
    select BFKEY, BFD19, BFDLOOUT, VLJ, DOCKET_INDEX
    from (
      select BFKEY, BFD19, BFDLOOUT, rownum DOCKET_INDEX,
        case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS end VLJ
      from (
        #{SELECT_READY_APPEALS}
        order by case when substr(TINUM, 1, 2) between '00' and '29' then 1 else 0 end, TINUM
      ) BRIEFF
      where BFAC <> '7' and AOD = '0'
      order by BFD19
    )
  "

  def self.counts_by_priority_and_readiness
    query = <<-SQL
      select count(*) N, PRIORITY, READY
      from (
        select case when BFAC = '7' or vacols_dev.aod_cnt(bfkey) > 0 then 1 else 0 end as PRIORITY,
          case when BFCURLOC in ('81', '83') and
            vacols_dev.mail_cnt_loc81(bfkey) = 0 and
            vacols_dev.diary_cnt_hold(bfkey) = 0
          then 1 else 0 end as READY
        from BRIEFF
        where BFMPRO <> 'HIS' and BFD19 is not null
      )
      group by PRIORITY, READY
    SQL

    connection.exec_query(query).to_hash
  end
  # rubocop:enable Metrics/MethodLength

  def self.genpop_priority_count
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where VLJ is null
    SQL

    connection.exec_query(query).to_hash.count
  end

  def self.genpop_nonpriority_count
    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS}
      where VLJ is null
    SQL

    connection.exec_query(query).to_hash.count
  end

  def self.not_genpop_priority_count
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where VLJ is not null
    SQL

    connection.exec_query(query).to_hash.count
  end

  def self.not_genpop_nonpriority_count
    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS}
      where VLJ is not null
    SQL

    connection.exec_query(query).to_hash.count
  end

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
          where HEARING_TYPE IN ('C', 'T', 'V', 'R')
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

  def self.age_of_n_oldest_genpop_priority_appeals(num)
    conn = connection

    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where VLJ is null and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, num])

    appeals = conn.exec_query(fmtd_query).to_hash
    appeals.map { |appeal| appeal["bfdloout"] }
  end

  def self.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    conn = connection

    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
      where (VLJ = ? or VLJ is null)
      and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, judge.vacols_attorney_id, num])

    appeals = conn.exec_query(fmtd_query).to_hash
    appeals.map { |appeal| appeal["bfd19"] }
  end

  def self.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    conn = connection

    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
      where (VLJ = ? or VLJ is null)
      and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, judge.vacols_attorney_id, num])

    appeals = conn.exec_query(fmtd_query).to_hash
    appeals.map { |appeal| appeal["bfd19"] }
  end

  def self.age_of_oldest_priority_appeal
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, 1])

    connection.exec_query(fmtd_query).to_hash.first&.fetch("bfdloout")
  end

  def self.age_of_oldest_priority_appeal_by_docket_date
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
      where rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, 1])

    connection.exec_query(fmtd_query).to_hash.first&.fetch("bfd19")
  end

  def self.nonpriority_decisions_per_year
    joins(VACOLS::Case::JOIN_AOD)
      .where(
        "BFDC in ('1', '3', '4') and BFDDEC >= ? and AOD = 0 and BFAC <> '7'",
        1.year.ago.to_date
      )
      .count
  end

  def self.priority_hearing_cases_for_judge_count(judge)
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where (VLJ = ?)
    SQL

    fmtd_query = sanitize_sql_array([query, judge.vacols_attorney_id])
    connection.exec_query(fmtd_query).count
  end

  def self.nonpriority_hearing_cases_for_judge_count(judge)
    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS}
      where (VLJ = ?)
    SQL

    fmtd_query = sanitize_sql_array([query, judge.vacols_attorney_id])
    connection.exec_query(fmtd_query).count
  end

  def self.priority_ready_appeal_vacols_ids
    connection.exec_query(SELECT_PRIORITY_APPEALS).to_hash.map { |appeal| appeal["bfkey"] }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists
  def self.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog, dry_run = false)
    fail(DocketNumberCentennialLoop, COPY::MAX_LEGACY_DOCKET_NUMBER_ERROR_MESSAGE) if Time.zone.now.year >= 2030

    if use_by_docket_date?
      query = <<-SQL
        #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
        where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and (DOCKET_INDEX <= ? or 1 = ?)
        and rownum <= ?
      SQL
    else
      # Docket numbers begin with the two digit year. The Board of Veterans Appeals was created in 1930.
      # Although there are no new legacy appeals after 2019, an old appeal can be reopened through a finding
      # of clear and unmistakable error, which would result in a brand new docket number being assigned.
      # An updated docket number format will need to be in place for legacy appeals by 2030 in order
      # to ensure that docket numbers are sorted correctly.

      # When requesting to bust the backlog of cases tied to a judge, distribute enough cases to get down to 30 while
      # still respecting the enforced limit on how many cases can be distributed
      if bust_backlog
        number_of_hearings_over_limit = nonpriority_hearing_cases_for_judge_count(judge) - HEARING_BACKLOG_LIMIT
        limit = (number_of_hearings_over_limit > 0) ? [number_of_hearings_over_limit, limit].min : 0
      end

      query = <<-SQL
        #{SELECT_NONPRIORITY_APPEALS}
        where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and (DOCKET_INDEX <= ? or 1 = ?)
        and rownum <= ?
      SQL
    end

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                      (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                      range,
                                      range.nil? ? 1 : 0,
                                      limit
                                    ])

    distribute_appeals(fmtd_query, judge, dry_run)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists

  def self.distribute_priority_appeals(judge, genpop, limit, dry_run = false)
    if use_by_docket_date?
      query = <<-SQL
        #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
        where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and (rownum <= ? or 1 = ?)
      SQL
    else
      query = <<-SQL
        #{SELECT_PRIORITY_APPEALS}
        where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and (rownum <= ? or 1 = ?)
      SQL
    end

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                      (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                      limit,
                                      limit.nil? ? 1 : 0
                                    ])

    distribute_appeals(fmtd_query, judge, dry_run)
  end

  # :nocov:

  def self.distribute_appeals(query, judge, dry_run)
    conn = connection

    conn.transaction do
      if dry_run
        conn.exec_query(query).to_hash
      else
        conn.execute(LOCK_READY_APPEALS) unless FeatureToggle.enabled?(:acd_disable_legacy_lock_ready_appeals)

        appeals = conn.exec_query(query).to_hash
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

  def self.use_by_docket_date?
    FeatureToggle.enabled?(:acd_distribute_by_docket_date, user: RequestStore.store[:current_user])
  end
end
