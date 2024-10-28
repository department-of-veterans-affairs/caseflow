# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class VACOLS::CaseDocket < VACOLS::Record
  # :nocov:
  self.table_name = "brieff"

  class DocketNumberCentennialLoop < StandardError; end

  HEARING_BACKLOG_LIMIT = 30

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

  FROM_READY_APPEALS = "
    from BRIEFF
    #{VACOLS::Case::JOIN_AOD}
    #{JOIN_MAIL_BLOCKS_DISTRIBUTION}
    #{JOIN_DIARY_BLOCKS_DISTRIBUTION}
    inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
    where BRIEFF.BFMPRO = 'ACT'
      and BRIEFF.BFCURLOC in ('81', '83')
      and BRIEFF.BFBOX is null
      and BRIEFF.BFAC is not null
      and BRIEFF.BFD19 is not null
      and MAIL_BLOCKS_DISTRIBUTION = 0
      and DIARY_BLOCKS_DISTRIBUTION = 0
  "

  SELECT_READY_APPEALS = "
    select BFKEY, BFD19, BFCORLID, BFDLOOUT, BFMPRO, BFCURLOC, BFAC, BFHINES, TINUM, TITRNUM, AOD,
    BFMEMID, BFDPDCN
    #{FROM_READY_APPEALS}
  "

  # this version of the query should not be used during distribution it is only intended for reporting usage
  SELECT_READY_APPEALS_ADDITIONAL_COLS = "
    select BFKEY, BFD19, BFDLOOUT, BFMPRO, BFCURLOC, BFAC, BFHINES, TINUM, TITRNUM, AOD, BFMEMID, BFDPDCN,
    BFCORKEY, BFCORLID
    #{FROM_READY_APPEALS}
  "

  # Judges 000, 888, and 999 are not real judges, but rather VACOLS codes.
  # This query will create multiple records/rows for each BRIEFF if the BRIEFF has multiple hearings
  # This may need to be accounted for by making sure the resultant set is filtered by BFKEY
  JOIN_ASSOCIATED_VLJS_BY_HEARINGS = "
    left join (
      select distinct TITRNUM, TINUM,
        first_value(HEARING_DATE) over (partition by TITRNUM, TINUM order by HEARING_DATE desc) HEARING_DATE,
        first_value(BOARD_MEMBER) over (partition by TITRNUM, TINUM order by HEARING_DATE desc) VLJ
      from HEARSCHED
      inner join FOLDER on FOLDER.TICKNUM = HEARSCHED.FOLDER_NR
      where HEARING_TYPE in ('C', 'T', 'V', 'R') and HEARING_DISP = 'H'
    ) VLJ_HEARINGS
      on VLJ_HEARINGS.VLJ not in ('000', '888', '999')
        and VLJ_HEARINGS.TITRNUM = BRIEFF.TITRNUM
        and (VLJ_HEARINGS.TINUM is null or VLJ_HEARINGS.TINUM = BRIEFF.TINUM)
  "

  # Provide access to legacy appeal decisions for more complete appeals history queries
  JOIN_PREVIOUS_APPEALS = "
  left join (
      select B.BFKEY as PREV_BFKEY, B.BFCORLID as PREV_BFCORLID, B.BFDDEC as PREV_BFDDEC,
      B.BFMEMID as PREV_DECIDING_JUDGE, B.BFAC as PREV_TYPE_ACTION, F.TINUM as PREV_TINUM,
      F.TITRNUM as PREV_TITRNUM
      from BRIEFF B
      inner join FOLDER F on F.TICKNUM = B.BFKEY
      where B.BFMPRO = 'HIS' and B.BFMEMID not in ('000', '888', '999') and B.BFATTID is not null
    ) PREV_APPEAL
      on PREV_APPEAL.PREV_BFKEY != BRIEFF.BFKEY and PREV_APPEAL.PREV_BFCORLID = BRIEFF.BFCORLID
      and PREV_APPEAL.PREV_TINUM = BRIEFF.TINUM and PREV_APPEAL.PREV_TITRNUM = BRIEFF.TITRNUM
      and PREV_APPEAL.PREV_BFDDEC = BRIEFF.BFDPDCN
  "

  SELECT_PRIORITY_APPEALS = "
    select BFKEY, BFDLOOUT, BFAC, AOD, VLJ, HEARING_DATE, BFDPDCN, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE
      from (
        select BFKEY, BFDLOOUT, BFAC, AOD, BFDPDCN,
          VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
          PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
          PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        from (
          #{SELECT_READY_APPEALS}
            and (BFAC = '7' or AOD = '1')
          order by BFDLOOUT
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_PREVIOUS_APPEALS}
      )
    "

  SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19 = "
    select BFKEY, BFD19, BFDLOOUT, BFAC, AOD, VLJ, HEARING_DATE, BFDPDCN, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE
      from (
        select BFKEY, BFD19, BFDLOOUT, BFAC, AOD, BFDPDCN,
          VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
          PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
          PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        from (
          #{SELECT_READY_APPEALS}
            and (BFAC = '7' or AOD = '1')
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_PREVIOUS_APPEALS}
        order by BFD19
      )
    "

  SELECT_NONPRIORITY_APPEALS = "
    select BFKEY, BFDLOOUT, VLJ, DOCKET_INDEX
    from (
      select BFKEY, BFDLOOUT, rownum DOCKET_INDEX,
        VLJ_HEARINGS.VLJ
      from (
        #{SELECT_READY_APPEALS}
          and BFAC <> '7' and AOD = '0'
        order by case when substr(TINUM, 1, 2) between '00' and '29' then 1 else 0 end, TINUM
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
    )
  "

  SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19 = "
    select BFKEY, BFD19, BFDLOOUT, VLJ, BFAC, DOCKET_INDEX, HEARING_DATE, BFDPDCN, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE
    from (
      select BFKEY, BFD19, BFDLOOUT, BFAC, rownum DOCKET_INDEX, BFDPDCN,
        VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
        PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
        PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
      from (
        #{SELECT_READY_APPEALS}
          and BFAC <> '7' and AOD = '0'
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      #{JOIN_PREVIOUS_APPEALS}
      order by BFD19
    )
  "

  # selects both priority and non-priority appeals that are ready to distribute
  SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19 = "
    select APPEALS.BFKEY, APPEALS.TINUM, APPEALS.BFD19, APPEALS.BFDLOOUT,
      case when APPEALS.BFAC = '7' or APPEALS.AOD = 1 then 1 else 0 end PRIORITY,
      APPEALS.VLJ, APPEALS.PREV_DECIDING_JUDGE, APPEALS.HEARING_DATE, APPEALS.PREV_BFDDEC
    from (
      select BRIEFF.BFKEY, BRIEFF.TINUM, BFD19, BFDLOOUT, BFAC, AOD,
        case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS.VLJ end VLJ
        , PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        , VLJ_HEARINGS.HEARING_DATE HEARING_DATE
        , PREV_APPEAL.PREV_BFDDEC PREV_BFDDEC
      from (
        #{SELECT_READY_APPEALS}
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      #{JOIN_PREVIOUS_APPEALS}
      order by BFD19
    ) APPEALS
  "

  # this query should not be used during distribution it is only intended for reporting usage
  SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19_ADDITIONAL_COLS = "
    select APPEALS.BFKEY, APPEALS.TINUM, APPEALS.BFD19, APPEALS.BFDLOOUT, APPEALS.AOD, APPEALS.BFCORLID,
      CORRES.SNAMEF, CORRES.SNAMEL, CORRES.SSN,
      STAFF.SNAMEF as VLJ_NAMEF, STAFF.SNAMEL as VLJ_NAMEL,
      case when APPEALS.BFAC = '7' then 1 else 0 end CAVC, PREV_TYPE_ACTION,
         PREV_DECIDING_JUDGE
    from (
      select BFKEY, BRIEFF.TINUM, BFD19, BFDLOOUT, BFAC, BFCORKEY, AOD, BFCORLID,
        VLJ_HEARINGS.VLJ,
        PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
        PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
      from (
        #{SELECT_READY_APPEALS_ADDITIONAL_COLS}
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      #{JOIN_PREVIOUS_APPEALS}
      order by BFD19
    ) APPEALS
    left join CORRES on APPEALS.BFCORKEY = CORRES.STAFKEY
    left join STAFF on APPEALS.VLJ = STAFF.SATTYID
    order by BFD19
  "

  FROM_LOC_63_APPEALS = "
    from BRIEFF
      #{VACOLS::Case::JOIN_AOD}
      inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
      where BRIEFF.BFCURLOC in ('63')
        and BRIEFF.BFBOX is null
        and BRIEFF.BFAC is not null
        and BRIEFF.BFD19 is not null
  "

  SELECT_LOC_63_APPEALS = "
    select BFKEY, BFD19, BFDLOCIN, BFCORLID, BFDLOOUT, BFMPRO, BFCORKEY, BFCURLOC, BFAC, BFHINES, TINUM, TITRNUM, AOD,
    BFMEMID, BFDPDCN
    #{FROM_LOC_63_APPEALS}
  "

  # rubocop:disable Metrics/MethodLength
  SELECT_APPEALS_IN_LOCATION_63_FROM_PAST_2_DAYS = "
    select APPEALS.BFKEY, APPEALS.TINUM, APPEALS.BFD19, APPEALS.BFMEMID, APPEALS.BFCURLOC,
      APPEALS.BFDLOCIN, APPEALS.BFCORLID, APPEALS.BFDLOOUT,
      case when APPEALS.BFAC = '7' or APPEALS.AOD = 1 then 1 else 0 end AOD,
      case when APPEALS.BFAC = '7' then 1 else 0 end CAVC,
      APPEALS.VLJ, APPEALS.PREV_DECIDING_JUDGE, APPEALS.HEARING_DATE, APPEALS.PREV_BFDDEC,
      CORRES.SNAMEF, CORRES.SNAMEL, CORRES.SSN,
      STAFF.SNAMEF as VLJ_NAMEF, STAFF.SNAMEL as VLJ_NAMEL
    from (
      select BRIEFF.BFKEY, BRIEFF.TINUM, BFD19, BFDLOOUT, BFAC, BFCORKEY, BFMEMID, BFCURLOC,
        BRIEFF.BFDLOCIN, BFCORLID, AOD,
        case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS.VLJ end VLJ
        , PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        , VLJ_HEARINGS.HEARING_DATE HEARING_DATE
        , PREV_APPEAL.PREV_BFDDEC PREV_BFDDEC
      from (
        #{SELECT_LOC_63_APPEALS}
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      #{JOIN_PREVIOUS_APPEALS}
      where BRIEFF.BFDLOCIN >= TRUNC(CURRENT_DATE) - 2
      order by BFD19
    ) APPEALS
    left join CORRES on APPEALS.BFCORKEY = CORRES.STAFKEY
    left join STAFF on APPEALS.VLJ = STAFF.SATTYID
  "

  def self.counts_by_priority_and_readiness
    query = <<-SQL
      select count(*) N, PRIORITY, READY
      from (
        select case when BFAC = '7' or nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0) > 0 then 1 else 0 end as PRIORITY,
          case when BFCURLOC in ('81', '83') and MAIL_BLOCKS_DISTRIBUTION = 0 and DIARY_BLOCKS_DISTRIBUTION = 0
            then 1 else 0 end as READY
        from BRIEFF
        #{JOIN_MAIL_BLOCKS_DISTRIBUTION}
        #{JOIN_DIARY_BLOCKS_DISTRIBUTION}
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
        where BFMPRO <> 'HIS' and BFD19 is not null
      )
      group by PRIORITY, READY
    SQL

    connection.exec_query(query).to_a
  end
  # rubocop:enable Metrics/MethodLength

  def self.genpop_priority_count
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where VLJ is null or #{ineligible_judges_sattyid_cache}
    SQL

    connection.exec_query(query).to_a.size
  end

  def self.not_genpop_priority_count
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where VLJ is not null
    SQL

    connection.exec_query(query).to_a.size
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
      where (VLJ is null or #{ineligible_judges_sattyid_cache} or #{ineligible_judges_sattyid_cache(true)}) and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, num])

    appeals = conn.exec_query(fmtd_query).to_a
    appeals.map { |appeal| appeal["bfdloout"] }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def self.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    cavc_affinity_lever_value = CaseDistributionLever.cavc_affinity_days
    cavc_aod_affinity_lever_value = CaseDistributionLever.cavc_aod_affinity_days

    judge_sattyid = judge.vacols_attorney_id
    excluded_judges_attorney_ids = excluded_judges_sattyids

    priority_cdl_query = generate_priority_case_distribution_lever_query(cavc_affinity_lever_value)
    priority_cdl_aod_query = generate_priority_case_distribution_lever_aod_query(cavc_aod_affinity_lever_value)

    conn = connection

    # {Query is broken up differently for when both levers are infinite due to a timeout caused by the large query}
    query = if cavc_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite &&
               cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite
              <<-SQL
              #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
              where (VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null
              or ((PREV_DECIDING_JUDGE = ? or #{ineligible_judges_sattyid_cache(true)}
              or #{vacols_judges_with_exclude_appeals_from_affinity(excluded_judges_attorney_ids)})
              and (#{priority_cdl_query} or #{priority_cdl_aod_query})))
              SQL
            else
              <<-SQL
              #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
              where (VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null
              or #{priority_cdl_query} or #{priority_cdl_aod_query})
              SQL
            end

    fmtd_query = if cavc_aod_affinity_lever_value != Constants.ACD_LEVERS.infinite &&
                    cavc_affinity_lever_value != Constants.ACD_LEVERS.infinite
                   sanitize_sql_array([
                                        query,
                                        judge_sattyid,
                                        judge_sattyid,
                                        judge_sattyid
                                      ])
                 else
                   sanitize_sql_array([
                                        query,
                                        judge_sattyid,
                                        judge_sattyid
                                      ])
                 end

    appeals = conn.exec_query(fmtd_query).to_a

    cavc_affinity_filter(appeals, judge_sattyid, cavc_affinity_lever_value, excluded_judges_attorney_ids)
    cavc_aod_affinity_filter(appeals, judge_sattyid, cavc_aod_affinity_lever_value, excluded_judges_attorney_ids)

    appeals.sort_by { |appeal| appeal[:bfd19] } if use_by_docket_date?

    appeals = appeals.first(num) unless num.nil? # {Reestablishes the limit}

    appeals.map { |appeal| appeal["bfd19"] }
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize

  def self.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    conn = connection

    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
      where (VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null)
      and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      num
                                    ])

    appeals = conn.exec_query(fmtd_query).to_a
    appeals.map { |appeal| appeal["bfd19"] }
  end

  def self.age_of_oldest_priority_appeal
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, 1])

    connection.exec_query(fmtd_query).to_a.first&.fetch("bfdloout")
  end

  def self.age_of_oldest_priority_appeal_by_docket_date
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
      where rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, 1])

    connection.exec_query(fmtd_query).to_a.first&.fetch("bfd19")
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
      where (VLJ = ? or #{ineligible_judges_sattyid_cache})
    SQL

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id
                                    ])
    connection.exec_query(fmtd_query).count
  end

  def self.nonpriority_hearing_cases_for_judge_count(judge)
    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS}
      where (VLJ = ? or #{ineligible_judges_sattyid_cache})
    SQL

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id
                                    ])
    connection.exec_query(fmtd_query).count
  end

  def self.priority_ready_appeal_vacols_ids
    connection.exec_query(SELECT_PRIORITY_APPEALS).to_a.map { |appeal| appeal["bfkey"] }
  end

  def self.ready_to_distribute_appeals
    query = <<-SQL
      #{SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19_ADDITIONAL_COLS}
    SQL

    fmtd_query = sanitize_sql_array([query])
    connection.exec_query(fmtd_query).to_a
  end

  def self.loc_63_appeals
    query = <<-SQL
      #{SELECT_APPEALS_IN_LOCATION_63_FROM_PAST_2_DAYS}
    SQL

    fmtd_query = sanitize_sql_array([query])
    connection.exec_query(fmtd_query).to_a
  end

  def self.appeals_tied_to_non_ssc_avljs
    query = <<-SQL
      with non_ssc_avljs as (
        #{VACOLS::Staff::NON_SSC_AVLJS}
      )
      #{SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19}
      where APPEALS.VLJ in (select * from non_ssc_avljs)
      and (
        APPEALS.PREV_DECIDING_JUDGE is null or
        (
          APPEALS.PREV_DECIDING_JUDGE = APPEALS.VLJ
          AND APPEALS.HEARING_DATE <= APPEALS.PREV_BFDDEC
        )
      )
      order by BFD19
    SQL

    fmtd_query = sanitize_sql_array([query])
    connection.exec_query(fmtd_query).to_a
  end

  def self.appeals_tied_to_avljs_and_vljs
    query = <<-SQL
      with all_avljs_andvljs as (
        #{VACOLS::Staff::ALL_AVLJS_AND_VLJS}
      )
      #{SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19}
      where APPEALS.VLJ in (select * from all_avljs_andvljs)
      order by BFD19
    SQL

    fmtd_query = sanitize_sql_array([query])
    connection.exec_query(fmtd_query).to_a
  end

  # rubocop:disable Metrics/MethodLength
  def self.update_appeal_affinity_dates_query(priority, date)
    priority_condition = if priority
                           "and (BFAC = '7' or AOD = '1')"
                         else
                           "and BFAC <> '7' and AOD = '0'"
                         end

    query = <<-SQL
      select APPEALS.BFKEY, APPEALS.TINUM, APPEALS.BFD19, APPEALS.BFDLOOUT, APPEALS.AOD, APPEALS.BFCORLID,
        CORRES.SNAMEF, CORRES.SNAMEL, CORRES.SSN,
        STAFF.SNAMEF as VLJ_NAMEF, STAFF.SNAMEL as VLJ_NAMEL,
        case when APPEALS.BFAC = '7' then 1 else 0 end CAVC, PREV_TYPE_ACTION,
        PREV_DECIDING_JUDGE
      from (
        select BFKEY, BRIEFF.TINUM, BFD19, BFDLOOUT, BFAC, BFCORKEY, AOD, BFCORLID,
          case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS.VLJ end VLJ,
          PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
          PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        from (
          #{SELECT_READY_APPEALS_ADDITIONAL_COLS}
          #{priority_condition}
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_PREVIOUS_APPEALS}
        order by BFD19
      ) APPEALS
      left join CORRES on APPEALS.BFCORKEY = CORRES.STAFKEY
      left join STAFF on APPEALS.VLJ = STAFF.STAFKEY
      where APPEALS.BFD19 <= TO_DATE('#{date}', 'YYYY-MM-DD HH24:MI:SS')
      order by BFD19
    SQL

    fmtd_query = sanitize_sql_array([query])
    connection.exec_query(fmtd_query).to_a
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists
  def self.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog, dry_run = false)
    fail(DocketNumberCentennialLoop, COPY::MAX_LEGACY_DOCKET_NUMBER_ERROR_MESSAGE) if Time.zone.now.year >= 2030

    if use_by_docket_date?
      query = <<-SQL
        #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
        where (((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?))
        and (DOCKET_INDEX <= ? or 1 = ?)
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
        where (((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?))
        and (DOCKET_INDEX <= ? or 1 = ?)
      SQL
    end

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                      (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                      range,
                                      range.nil? ? 1 : 0
                                    ])

    distribute_appeals(fmtd_query, judge, limit, genpop, dry_run)
  end

  # rubocop:disable Metrics/AbcSize
  def self.distribute_priority_appeals(judge, genpop, limit, dry_run = false)
    cavc_affinity_lever_value = CaseDistributionLever.cavc_affinity_days
    cavc_aod_affinity_lever_value = CaseDistributionLever.cavc_aod_affinity_days

    judge_sattyid = judge.vacols_attorney_id
    excluded_judges_attorney_ids = excluded_judges_sattyids

    priority_cdl_query = generate_priority_case_distribution_lever_query(cavc_affinity_lever_value)
    priority_cdl_aod_query = generate_priority_case_distribution_lever_aod_query(cavc_aod_affinity_lever_value)

    # {Query is broken up differently for when both levers are infinite due to a timeout caused by the large query}
    query = if use_by_docket_date? && cavc_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite &&
               cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite
              <<-SQL
                #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
                where (((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?)
                or (VLJ is null and 1 = ?)
                or ((PREV_DECIDING_JUDGE = ? or #{ineligible_judges_sattyid_cache(true)}
                or #{vacols_judges_with_exclude_appeals_from_affinity(excluded_judges_attorney_ids)})
                and (#{priority_cdl_query} or #{priority_cdl_aod_query})))
              SQL
            elsif use_by_docket_date?
              <<-SQL
                #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
                where (((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?)
                or (VLJ is null and 1 = ?) or #{priority_cdl_query} or #{priority_cdl_aod_query})
              SQL
            else
              <<-SQL
                #{SELECT_PRIORITY_APPEALS}
                where (((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?)
                or (VLJ is null and 1 = ?) or #{priority_cdl_query} or #{priority_cdl_aod_query})
              SQL
            end

    fmtd_query = if cavc_aod_affinity_lever_value != Constants.ACD_LEVERS.infinite &&
                    cavc_affinity_lever_value != Constants.ACD_LEVERS.infinite
                   sanitize_sql_array([
                                        query,
                                        judge_sattyid,
                                        (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                        (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                        judge_sattyid,
                                        judge_sattyid
                                      ])
                 else
                   sanitize_sql_array([
                                        query,
                                        judge_sattyid,
                                        (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                        (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                        judge_sattyid
                                      ])
                 end

    distribute_appeals(fmtd_query, judge, limit, genpop, dry_run)
  end
  # :nocov:

  def self.distribute_appeals(query, judge, limit, genpop, dry_run)
    cavc_affinity_lever_value = CaseDistributionLever.cavc_affinity_days
    cavc_aod_affinity_lever_value = CaseDistributionLever.cavc_aod_affinity_days
    excluded_judges_attorney_ids = excluded_judges_sattyids
    judge_sattyid = judge.vacols_attorney_id

    conn = connection

    conn.transaction do
      if dry_run
        dry_appeals = conn.exec_query(query).to_a

        cavc_affinity_filter(dry_appeals, judge_sattyid, cavc_affinity_lever_value, excluded_judges_attorney_ids, genpop)
        cavc_aod_affinity_filter(dry_appeals, judge_sattyid, cavc_aod_affinity_lever_value,
                                 excluded_judges_attorney_ids, genpop)

        genpop_filter(dry_appeals) if genpop == "not_genpop"

        dry_appeals
      else
        conn.execute(LOCK_READY_APPEALS) unless FeatureToggle.enabled?(:acd_disable_legacy_lock_ready_appeals)

        appeals = conn.exec_query(query).to_a
        return appeals if appeals.empty?

        cavc_affinity_filter(appeals, judge_sattyid, cavc_affinity_lever_value, excluded_judges_attorney_ids, genpop)
        cavc_aod_affinity_filter(appeals, judge_sattyid, cavc_aod_affinity_lever_value, excluded_judges_attorney_ids, genpop)

        genpop_filter(appeals) if genpop == "not_genpop"

        appeals.sort_by { |appeal| appeal[:bfd19] } if use_by_docket_date?

        appeals = appeals.first(limit) unless limit.nil? # {Reestablishes the limit}

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
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/ParameterLists

  def self.generate_priority_case_distribution_lever_query(cavc_affinity_lever_value)
    if case_affinity_days_lever_value_is_selected?(cavc_affinity_lever_value) ||
       cavc_affinity_lever_value == Constants.ACD_LEVERS.omit
      "((PREV_DECIDING_JUDGE = ? or PREV_DECIDING_JUDGE is null or PREV_DECIDING_JUDGE is not null)
      and AOD = '0' and BFAC = '7')"
    elsif cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite
      "(AOD = '0' and BFAC = '7')"
    else
      "VLJ = ?"
    end
  end

  def self.generate_priority_case_distribution_lever_aod_query(cavc_aod_affinity_lever_value)
    if case_affinity_days_lever_value_is_selected?(cavc_aod_affinity_lever_value) ||
       cavc_aod_affinity_lever_value == Constants.ACD_LEVERS.omit
      "((PREV_DECIDING_JUDGE = ? or PREV_DECIDING_JUDGE is null or PREV_DECIDING_JUDGE is not null)
      and AOD = '1' and BFAC = '7' )"
    elsif cavc_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite
      "(AOD = '1' and BFAC = '7')"
    else
      "VLJ = ?"
    end
  end

  def self.use_by_docket_date?
    FeatureToggle.enabled?(:acd_distribute_by_docket_date, user: RequestStore.store[:current_user])
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  def self.cavc_affinity_filter(appeals, judge_sattyid, cavc_affinity_lever_value, excluded_judges_attorney_ids, genpop = "any")
    appeals.reject! do |appeal|
      next if tied_to_or_not_cavc?(appeal, judge_sattyid, genpop)

      if not_distributing_to_tied_judge?(appeal, judge_sattyid)
        next if ineligible_judges_sattyids.include?(appeal["vlj"]) && genpop != "not_genpop"

        next (appeal["vlj"] != judge_sattyid)
      end

      if appeal_has_hearing_after_previous_decision?(appeal)
        next if appeal["vlj"] == judge_sattyid
        next true if !ineligible_judges_sattyids.include?(appeal["vlj"])
      end

      next if ineligible_or_excluded_deciding_judge?(appeal, excluded_judges_attorney_ids) && genpop != "not_genpop"

      if case_affinity_days_lever_value_is_selected?(cavc_affinity_lever_value)
        if appeal["prev_deciding_judge"] == judge_sattyid
          if genpop == "not_genpop"
            next !reject_due_to_affinity?(appeal, cavc_affinity_lever_value)
          elsif genpop != "not_genpop"
            next
          end
        end

        genpop == "not_genpop" || reject_due_to_affinity?(appeal, cavc_affinity_lever_value)
      elsif cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite
        next if hearing_judge_ineligible_with_no_hearings_after_decision(appeal)

        appeal["prev_deciding_judge"] != judge_sattyid
      elsif cavc_affinity_lever_value == Constants.ACD_LEVERS.omit
        appeal["prev_deciding_judge"] == appeal["vlj"] || genpop == "not_genpop"
      end
    end
  end

  def self.cavc_aod_affinity_filter(appeals, judge_sattyid, cavc_aod_affinity_lever_value, excluded_judges_attorney_ids, genpop = "any")
    appeals.reject! do |appeal|
      # {will skip if not CAVC AOD || if CAVC AOD being distributed to tied_to judge || if not tied to any judge}
      next if tied_to_or_not_cavc_aod?(appeal, judge_sattyid, genpop)

      if not_distributing_to_tied_judge?(appeal, judge_sattyid)
        next if ineligible_judges_sattyids&.include?(appeal["vlj"]) && genpop != "not_genpop"

        next (appeal["vlj"] != judge_sattyid)
      end

      if appeal_has_hearing_after_previous_decision?(appeal)
        next if appeal["vlj"] == judge_sattyid
        next true if !ineligible_judges_sattyids.include?(appeal["vlj"])
      end

      next if ineligible_or_excluded_deciding_judge?(appeal, excluded_judges_attorney_ids) && genpop != "not_genpop"

      if case_affinity_days_lever_value_is_selected?(cavc_aod_affinity_lever_value)
        if appeal["prev_deciding_judge"] == judge_sattyid
          if genpop == "not_genpop"
            next !reject_due_to_affinity?(appeal, cavc_aod_affinity_lever_value)
          elsif genpop != "not_genpop"
            next
          end
        end

        genpop == "not_genpop" || reject_due_to_affinity?(appeal, cavc_aod_affinity_lever_value)
      elsif cavc_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite
        next if hearing_judge_ineligible_with_no_hearings_after_decision(appeal)

        appeal["prev_deciding_judge"] != judge_sattyid
      elsif cavc_aod_affinity_lever_value == Constants.ACD_LEVERS.omit
        appeal["prev_deciding_judge"] == appeal["vlj"] || genpop == "not_genpop"
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  # this will currently only apply to priority appeals via the push priority job because we don't pass
  # "not_genpop" through any nonpriority distributions
  def self.genpop_filter(appeals)
    appeals.reject! do |appeal|
      # bfac 3 = AOJ and bfac 7 = CAVC which are filtered in their own methods to account for affinities
      next if %w[3 7].include?(appeal["bfac"])

      appeal["vlj"].nil? || ineligible_judges_sattyids&.include?(appeal["vlj"])
    end
  end

  def self.tied_to_or_not_cavc?(appeal, judge_sattyid, genpop)
    (appeal["bfac"] != "7" || appeal["aod"] != 0) ||
      (appeal["bfac"] == "7" && appeal["aod"] == 0 &&
        !appeal["vlj"].blank? &&
        (appeal["vlj"] == appeal["prev_deciding_judge"] || appeal["prev_deciding_judge"].nil?) &&
        appeal["vlj"] == judge_sattyid) ||
      (appeal["vlj"].nil? && appeal["prev_deciding_judge"].nil? && genpop != "not_genpop")
  end

  def self.tied_to_or_not_cavc_aod?(appeal, judge_sattyid, genpop)
    (appeal["bfac"] != "7" || appeal["aod"] != 1) ||
      (appeal["bfac"] == "7" && appeal["aod"] == 1 &&
        !appeal["vlj"].blank? &&
        (appeal["vlj"] == appeal["prev_deciding_judge"] || appeal["prev_deciding_judge"].nil?) &&
        appeal["vlj"] == judge_sattyid) ||
      (appeal["vlj"].nil? && appeal["prev_deciding_judge"].nil? && genpop != "not_genpop")
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def self.not_distributing_to_tied_judge?(appeal, judge_sattyid)
    !appeal["vlj"].blank? &&
      (appeal["vlj"] == appeal["prev_deciding_judge"]) &&
      (appeal["vlj"] != judge_sattyid)
  end

  def self.appeal_has_hearing_after_previous_decision?(appeal)
    (!appeal["hearing_date"].nil? && !appeal["bfdpdcn"].nil? && appeal["hearing_date"] > appeal["bfdpdcn"])
  end

  def self.ineligible_or_excluded_deciding_judge?(appeal, excluded_judges_attorney_ids)
    # {if deciding_judge is ineligible or excluded, we will skip, unless excluded deciding_judge = VLJ}
    ineligible_judges_sattyids&.include?(appeal["prev_deciding_judge"]) ||
      (appeal["vlj"] != appeal["prev_deciding_judge"] &&
        excluded_judges_attorney_ids&.include?(appeal["prev_deciding_judge"]))
  end

  def self.reject_due_to_affinity?(appeal, lever)
    VACOLS::Case.find_by(bfkey: appeal["bfkey"])&.appeal_affinity&.affinity_start_date.nil? ||
      (VACOLS::Case.find_by(bfkey: appeal["bfkey"])
        .appeal_affinity
        .affinity_start_date > lever.to_i.days.ago)
  end

  def self.hearing_judge_ineligible_with_no_hearings_after_decision(appeal)
    ineligible_judges_sattyids&.include?(appeal["vlj"]) && !appeal_has_hearing_after_previous_decision?(appeal)
  end

  def self.ineligible_judges_sattyids
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:sattyid)&.reject(&:blank?) || []
  end

  def self.excluded_judges_sattyids
    VACOLS::Staff.where(sdomainid: JudgeTeam.active
        .where(exclude_appeals_from_affinity: true)
        .flat_map(&:judge).compact.pluck(:css_id))&.pluck(:sattyid)
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  def self.ineligible_judges_sattyid_cache(prev_deciding_judge = false)
    if FeatureToggle.enabled?(:acd_cases_tied_to_judges_no_longer_with_board) &&
       !ineligible_judges_sattyids.blank?
      list = ineligible_judges_sattyids
      split_lists = {}
      num_of_lists = (list.size.to_f / 999).ceil
      num_of_lists.times do |num|
        split_lists[num] = []
        999.times do
          split_lists[num] << list.shift
        end
        split_lists[num].compact!
      end

      vljs_strings = split_lists.flat_map do |k, v|
        # running array.join(', ') creates a string where each ID is considered an integer which causes issues
        # in the VACOLS queries if a user's SATTYID has leading zeroes (which exists in production)
        base = ""
        v.map { |vlj_id| base += "'#{vlj_id}', " }
        2.times { base.chop! }
        base = "(#{base})"

        if prev_deciding_judge
          base += " or PREV_DECIDING_JUDGE in " unless k == split_lists.keys.last
        else
          base += " or VLJ in " unless k == split_lists.keys.last
        end
        base
      end

      if prev_deciding_judge
        "PREV_DECIDING_JUDGE in #{vljs_strings.join}"
      else
        "VLJ in #{vljs_strings.join}"
      end
    elsif prev_deciding_judge
      "PREV_DECIDING_JUDGE = 'false'"
    else
      "VLJ = 'false'"
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize

  def self.vacols_judges_with_exclude_appeals_from_affinity(excluded_judges_attorney_ids)
    return "PREV_DECIDING_JUDGE = 'false'" unless FeatureToggle.enabled?(:acd_exclude_from_affinity)

    if excluded_judges_attorney_ids.blank?
      "PREV_DECIDING_JUDGE = 'false'"
    else
      "PREV_DECIDING_JUDGE in (#{excluded_judges_attorney_ids.join(', ')})"
    end
  end

  def self.case_affinity_days_lever_value_is_selected?(lever_value)
    return false if lever_value == "omit" || lever_value == "infinite"

    true
  end
end
# rubocop:enable Metrics/ClassLength
