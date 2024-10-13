# frozen_string_literal: true

class VACOLS::AojCaseDocket < VACOLS::CaseDocket # rubocop:disable Metrics/ClassLength
  # :nocov:
  self.table_name = "brieff"

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
      and BRIEFF.BFAC = '3'
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

  JOIN_PREVIOUS_APPEALS = "
  left join (
      select B.BFKEY as PREV_BFKEY, B.BFCORLID as PREV_BFCORLID, B.BFDDEC as PREV_BFDDEC,
      B.BFMEMID as PREV_DECIDING_JUDGE, B.BFAC as PREV_TYPE_ACTION, F.TINUM as PREV_TINUM,
      F.TITRNUM as PREV_TITRNUM
      from BRIEFF B
      inner join FOLDER F on F.TICKNUM = B.BFKEY

      where B.BFMPRO = 'HIS'
    ) PREV_APPEAL
      on PREV_APPEAL.PREV_BFKEY != BRIEFF.BFKEY and PREV_APPEAL.PREV_BFCORLID = BRIEFF.BFCORLID
      and PREV_APPEAL.PREV_TINUM = BRIEFF.TINUM and PREV_APPEAL.PREV_TITRNUM = BRIEFF.TITRNUM
      and PREV_APPEAL.PREV_BFDDEC = BRIEFF.BFDPDCN
  "

  SELECT_PRIORITY_APPEALS = "
    select BFKEY, BFDLOOUT, BFAC, AOD, VLJ, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE, HEARING_DATE, BFDPDCN
      from (
        select BFKEY, BFDLOOUT, BFAC, AOD, BFDPDCN,
          VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
          PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
          PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        from (
          #{SELECT_READY_APPEALS}
          order by BFDLOOUT
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_PREVIOUS_APPEALS}
      )
    "

  SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19 = "
    select BFKEY, BFD19, BFDLOOUT, BFAC, AOD, VLJ, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE, HEARING_DATE, BFDPDCN
      from (
        select BFKEY, BFD19, BFDLOOUT, BFAC, AOD, BFDPDCN,
          VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
          PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
          PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        from (
          #{SELECT_READY_APPEALS}
        ) BRIEFF
        #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
        #{JOIN_PREVIOUS_APPEALS}
        order by BFD19
      )
    "

  SELECT_NONPRIORITY_APPEALS = "
    select BFKEY, BFDLOOUT, AOD, VLJ, DOCKET_INDEX, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE, HEARING_DATE, BFDPDCN
    from (
      select BFKEY, BFDLOOUT, AOD, rownum DOCKET_INDEX, BFDPDCN,
        VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
        PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
        PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
      from (
        #{SELECT_READY_APPEALS}
        order by case when substr(TINUM, 1, 2) between '00' and '29' then 1 else 0 end, TINUM
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      #{JOIN_PREVIOUS_APPEALS}
    )
  "

  SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19 = "
    select BFKEY, BFD19, BFDLOOUT, AOD, VLJ, BFAC, DOCKET_INDEX, PREV_TYPE_ACTION, PREV_DECIDING_JUDGE,
     HEARING_DATE, BFDPDCN
    from (
      select BFKEY, BFD19, BFDLOOUT, AOD, BFAC, rownum DOCKET_INDEX, BFDPDCN,
        VLJ_HEARINGS.VLJ, VLJ_HEARINGS.HEARING_DATE,
         PREV_APPEAL.PREV_TYPE_ACTION PREV_TYPE_ACTION,
         PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
      from (
        #{SELECT_READY_APPEALS}
      ) BRIEFF
      #{JOIN_ASSOCIATED_VLJS_BY_HEARINGS}
      #{JOIN_PREVIOUS_APPEALS}
      order by BFD19
    )
  "

  # selects both priority and non-priority appeals that are ready to distribute
  SELECT_READY_TO_DISTRIBUTE_APPEALS_ORDER_BY_BFD19 = "
    select APPEALS.BFKEY, APPEALS.TINUM, APPEALS.BFD19, APPEALS.BFDLOOUT,
      case when APPEALS.PREV_TYPE_ACTION = '7' or APPEALS.AOD = 1 then 1 else 0 end PRIORITY,
      APPEALS.VLJ, APPEALS.PREV_DECIDING_JUDGE, APPEALS.HEARING_DATE, APPEALS.PREV_BFDDEC
    from (
      select BRIEFF.BFKEY, BRIEFF.TINUM, BFD19, BFDLOOUT, BFAC, AOD,
        case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS.VLJ end VLJ
        , PREV_APPEAL.PREV_DECIDING_JUDGE PREV_DECIDING_JUDGE
        , VLJ_HEARINGS.HEARING_DATE HEARING_DATE
        , PREV_APPEAL.PREV_BFDDEC PREV_BFDDEC
        , PREV_APPEAL.PREV_TYPE_ACTION
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
      case when APPEALS.PREV_TYPE_ACTION = '7' then 1 else 0 end CAVC, PREV_TYPE_ACTION,
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

  # rubocop:disable Metrics/MethodLength
  def self.counts_by_priority_and_readiness
    query = <<-SQL
      select count(*) N, PRIORITY, READY
      from (
        select case when BFAC = '3' and (PREV_APPEAL.PREV_TYPE_ACTION = '7' or nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0) > 0) then 1 else 0 end as PRIORITY,
          case when BFCURLOC in ('81', '83') and MAIL_BLOCKS_DISTRIBUTION = 0 and DIARY_BLOCKS_DISTRIBUTION = 0
            then 1 else 0 end as READY, TITRNUM, TINUM
        from BRIEFF
        inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
        #{JOIN_MAIL_BLOCKS_DISTRIBUTION}
        #{JOIN_DIARY_BLOCKS_DISTRIBUTION}
        left join (
          select B.BFKEY as PREV_BFKEY, B.BFCORLID as PREV_BFCORLID, B.BFDDEC as PREV_BFDDEC,
          B.BFMEMID as PREV_DECIDING_JUDGE, B.BFAC as PREV_TYPE_ACTION, F.TINUM as PREV_TINUM,
          F.TITRNUM as PREV_TITRNUM
          from BRIEFF B
          inner join FOLDER F on F.TICKNUM = B.BFKEY

          where B.BFMPRO = 'HIS' and B.BFMEMID not in ('000', '888', '999') and B.BFATTID is not null
        ) PREV_APPEAL
          on PREV_APPEAL.PREV_BFKEY != BRIEFF.BFKEY and PREV_APPEAL.PREV_BFCORLID = BRIEFF.BFCORLID
          and PREV_APPEAL.PREV_TINUM = TINUM and PREV_APPEAL.PREV_TITRNUM = TITRNUM
          and PREV_APPEAL.PREV_BFDDEC = BRIEFF.BFDPDCN
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
        where BFMPRO <> 'HIS' and BFD19 is not null and BFAC = '3'
      )
      group by PRIORITY, READY
    SQL

    connection.exec_query(query).to_a
  end
  # rubocop:enable Metrics/MethodLength

  def self.genpop_priority_count
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where (VLJ is null or VLJ != PREV_DECIDING_JUDGE or #{ineligible_judges_sattyid_cache}) and (PREV_TYPE_ACTION = '7' or AOD = '1')
    SQL

    filter_genpop_appeals_for_affinity(query).size
  end

  def self.not_genpop_priority_count
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where VLJ is not null and (PREV_TYPE_ACTION = '7' or AOD = '1')
    SQL

    connection.exec_query(query).to_a.size
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def self.age_of_n_oldest_priority_appeals_available_to_judge(judge, num)
    aoj_cavc_affinity_lever_value = CaseDistributionLever.aoj_cavc_affinity_days
    aoj_aod_affinity_lever_value = CaseDistributionLever.aoj_aod_affinity_days

    judge_sattyid = judge.vacols_attorney_id
    excluded_judges_attorney_ids = excluded_judges_sattyids

    priority_aoj_cdl_query = generate_priority_aoj_case_distribution_lever_query(aoj_cavc_affinity_lever_value)
    priority_cdl_aoj_aod_query = generate_priority_case_distribution_lever_aoj_aod_query(aoj_aod_affinity_lever_value)

    conn = connection

    query = if aoj_cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite &&
               aoj_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite
              <<-SQL
                  #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
                  where ((VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null)
                  and (PREV_TYPE_ACTION = '7' or AOD = '1')
                  or ((PREV_DECIDING_JUDGE = ? or #{ineligible_judges_sattyid_cache(true)}
                  or #{vacols_judges_with_exclude_appeals_from_affinity(excluded_judges_attorney_ids)})
                  and (#{priority_aoj_cdl_query} or #{priority_cdl_aoj_aod_query})))
              SQL
            else
              <<-SQL
                  #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
                  where (VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null)
                  and (PREV_TYPE_ACTION = '7' or AOD = '1')
                  or #{priority_aoj_cdl_query}
                  or #{priority_cdl_aoj_aod_query}
              SQL
            end

    fmtd_query = if aoj_cavc_affinity_lever_value != Constants.ACD_LEVERS.infinite &&
                    aoj_aod_affinity_lever_value != Constants.ACD_LEVERS.infinite
                   sanitize_sql_array([
                                        query,
                                        judge.vacols_attorney_id,
                                        judge.vacols_attorney_id,
                                        judge.vacols_attorney_id
                                      ])
                 else
                   sanitize_sql_array([
                                        query,
                                        judge.vacols_attorney_id,
                                        judge.vacols_attorney_id
                                      ])
                 end

    appeals = conn.exec_query(fmtd_query).to_a

    aoj_cavc_affinity_filter(appeals, judge_sattyid, aoj_cavc_affinity_lever_value, excluded_judges_attorney_ids)
    aoj_aod_affinity_filter(appeals, judge_sattyid, aoj_aod_affinity_lever_value, excluded_judges_attorney_ids)

    appeals.sort_by { |appeal| appeal[:bfd19] } if use_by_docket_date?

    appeals = appeals.first(num) unless num.nil? # {Reestablishes the limit}

    appeals.map { |appeal| appeal["bfd19"] }
  end

  def self.age_of_n_oldest_nonpriority_appeals_available_to_judge(judge, num)
    aoj_affinity_lever_value = CaseDistributionLever.aoj_affinity_days

    judge_sattyid = judge.vacols_attorney_id
    excluded_judges_attorney_ids = excluded_judges_sattyids

    nonpriority_cdl_aoj_query = generate_nonpriority_case_distribution_lever_aoj_query(aoj_affinity_lever_value)
    conn = connection

    query = if aoj_affinity_lever_value == Constants.ACD_LEVERS.infinite
              <<-SQL
                #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
                where ((VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null)
                and ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')
                or ((PREV_DECIDING_JUDGE = ? or #{ineligible_judges_sattyid_cache(true)}
                or #{vacols_judges_with_exclude_appeals_from_affinity(excluded_judges_attorney_ids)})
                or #{nonpriority_cdl_aoj_query}))
              SQL
            else
              <<-SQL
                #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
                where ((VLJ = ? or #{ineligible_judges_sattyid_cache} or VLJ is null)
                and ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')
                or #{nonpriority_cdl_aoj_query})
              SQL
            end

    fmtd_query = sanitize_sql_array([
                                      query,
                                      judge.vacols_attorney_id,
                                      judge.vacols_attorney_id
                                    ])

    appeals = conn.exec_query(fmtd_query).to_a

    aoj_affinity_filter(appeals, judge_sattyid, aoj_affinity_lever_value, excluded_judges_attorney_ids)

    appeals.sort_by { |appeal| appeal[:bfd19] } if use_by_docket_date?

    appeals = appeals.first(num) unless num.nil? # {Reestablishes the limit}

    appeals.map { |appeal| appeal["bfd19"] }
  end

  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def self.age_of_oldest_priority_appeal
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where (PREV_TYPE_ACTION = '7' or AOD = '1') and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, 1])

    connection.exec_query(fmtd_query).to_a.first&.fetch("bfdloout")
  end

  def self.age_of_oldest_priority_appeal_by_docket_date
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
      where (PREV_TYPE_ACTION = '7' or AOD = '1') and rownum <= ?
    SQL

    fmtd_query = sanitize_sql_array([query, 1])

    connection.exec_query(fmtd_query).to_a.first&.fetch("bfd19")
  end

  def self.priority_hearing_cases_for_judge_count(judge)
    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS}
      where (VLJ = ? or #{ineligible_judges_sattyid_cache}) and (PREV_TYPE_ACTION = '7' or AOD = '1')
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
      and ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')
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

  # rubocop:disable Metrics/MethodLength
  def self.update_appeal_affinity_dates_query(priority, date)
    priority_condition = if priority
                           "and (PREV_TYPE_ACTION = '7' or AOD = '1')"
                         else
                           "and ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')"
                         end

    query = <<-SQL
      select APPEALS.BFKEY, APPEALS.TINUM, APPEALS.BFD19, APPEALS.BFDLOOUT, APPEALS.AOD, APPEALS.BFCORLID,
        CORRES.SNAMEF, CORRES.SNAMEL, CORRES.SSN,
        STAFF.SNAMEF as VLJ_NAMEF, STAFF.SNAMEL as VLJ_NAMEL,
        case when APPEALS.PREV_TYPE_ACTION = '7' then 1 else 0 end CAVC, APPEALS.PREV_TYPE_ACTION,
        APPEALS.PREV_DECIDING_JUDGE
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
      left join STAFF on APPEALS.VLJ = STAFF.STAFKEY
      where APPEALS.BFD19 <= TO_DATE('#{date}', 'YYYY-MM-DD HH24:MI:SS')
      #{priority_condition}
      order by BFD19
    SQL

    fmtd_query = sanitize_sql_array([query])
    connection.exec_query(fmtd_query).to_a
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists, Metrics/AbcSize

  def self.distribute_nonpriority_appeals(judge, genpop, range, limit, bust_backlog, dry_run = false)
    fail(DocketNumberCentennialLoop, COPY::MAX_LEGACY_DOCKET_NUMBER_ERROR_MESSAGE) if Time.zone.now.year >= 2030

    aoj_affinity_lever_value = CaseDistributionLever.aoj_affinity_days

    nonpriority_cdl_aoj_query = generate_nonpriority_case_distribution_lever_aoj_query(aoj_affinity_lever_value)

    if use_by_docket_date?
      query = <<-SQL
        #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
        where ((((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?))
        and ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')
        or #{nonpriority_cdl_aoj_query})
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
        where ((((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?))
        and ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')
        or #{nonpriority_cdl_aoj_query})
        and (DOCKET_INDEX <= ? or 1 = ?)
      SQL
    end

    fmtd_query = if aoj_affinity_lever_value == Constants.ACD_LEVERS.infinite
                   sanitize_sql_array([
                                        query,
                                        judge.vacols_attorney_id,
                                        (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                        (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                        range,
                                        range.nil? ? 1 : 0
                                      ])
                 else
                   sanitize_sql_array([
                                        query,
                                        judge.vacols_attorney_id,
                                        (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                        (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                        judge.vacols_attorney_id,
                                        range,
                                        range.nil? ? 1 : 0
                                      ])
                 end

    distribute_appeals(fmtd_query, judge, limit, dry_run)
  end

  def self.distribute_priority_appeals(judge, genpop, limit, dry_run = false)
    aoj_cavc_affinity_lever_value = CaseDistributionLever.aoj_cavc_affinity_days
    aoj_aod_affinity_lever_value = CaseDistributionLever.aoj_aod_affinity_days
    excluded_judges_attorney_ids = excluded_judges_sattyids

    priority_aoj_cdl_query = generate_priority_aoj_case_distribution_lever_query(aoj_cavc_affinity_lever_value)
    priority_cdl_aoj_aod_query = generate_priority_case_distribution_lever_aoj_aod_query(aoj_aod_affinity_lever_value)

    query = if use_by_docket_date? && aoj_cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite &&
               aoj_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite
              <<-SQL
                #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
                where (((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?)
                and (PREV_TYPE_ACTION = '7' or AOD = '1')
                or ((PREV_DECIDING_JUDGE = ? or #{ineligible_judges_sattyid_cache(true)}
                or #{vacols_judges_with_exclude_appeals_from_affinity(excluded_judges_attorney_ids)})
                and (#{priority_aoj_cdl_query} or #{priority_cdl_aoj_aod_query})))
              SQL
            elsif use_by_docket_date?
              <<-SQL
                #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
                where ((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?)
                and (PREV_TYPE_ACTION = '7' or AOD = '1')
                or #{priority_aoj_cdl_query} or #{priority_cdl_aoj_aod_query}
              SQL
            else
              <<-SQL
                #{SELECT_PRIORITY_APPEALS}
                where ((VLJ = ? or #{ineligible_judges_sattyid_cache}) and 1 = ?) or (VLJ is null and 1 = ?)
                and (PREV_TYPE_ACTION = '7' or AOD = '1')
                or #{priority_aoj_cdl_query} or #{priority_cdl_aoj_aod_query}
              SQL
            end

    fmtd_query = if aoj_cavc_affinity_lever_value != Constants.ACD_LEVERS.infinite &&
                    aoj_aod_affinity_lever_value != Constants.ACD_LEVERS.infinite
                   sanitize_sql_array([
                                        query,
                                        judge.vacols_attorney_id,
                                        (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                        (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                        judge.vacols_attorney_id,
                                        judge.vacols_attorney_id
                                      ])
                 else
                   sanitize_sql_array([
                                        query,
                                        judge.vacols_attorney_id,
                                        (genpop == "any" || genpop == "not_genpop") ? 1 : 0,
                                        (genpop == "any" || genpop == "only_genpop") ? 1 : 0,
                                        judge.vacols_attorney_id
                                      ])
                 end

    distribute_appeals(fmtd_query, judge, limit, dry_run)
  end

  # :nocov:
  def self.distribute_appeals(query, judge, limit, dry_run)
    aoj_cavc_affinity_lever_value = CaseDistributionLever.aoj_cavc_affinity_days
    aoj_aod_affinity_lever_value = CaseDistributionLever.aoj_aod_affinity_days
    aoj_affinity_lever_value = CaseDistributionLever.aoj_affinity_days
    excluded_judges_attorney_ids = excluded_judges_sattyids
    judge_sattyid = judge.vacols_attorney_id

    conn = connection

    conn.transaction do
      if dry_run
        dry_appeals = conn.exec_query(query).to_a

        aoj_affinity_filter(dry_appeals, judge_sattyid, aoj_affinity_lever_value, excluded_judges_attorney_ids)

        aoj_cavc_affinity_filter(dry_appeals, judge_sattyid, aoj_cavc_affinity_lever_value, excluded_judges_attorney_ids) # rubocop:disable Layout/LineLength

        aoj_aod_affinity_filter(dry_appeals, judge_sattyid, aoj_aod_affinity_lever_value,
                                excluded_judges_attorney_ids)

        dry_appeals
      else
        conn.execute(LOCK_READY_APPEALS) unless FeatureToggle.enabled?(:acd_disable_legacy_lock_ready_appeals)

        appeals = conn.exec_query(query).to_a
        return appeals if appeals.empty?

        aoj_affinity_filter(appeals, judge_sattyid, aoj_affinity_lever_value, excluded_judges_attorney_ids)

        aoj_cavc_affinity_filter(appeals, judge_sattyid, aoj_cavc_affinity_lever_value, excluded_judges_attorney_ids)

        aoj_aod_affinity_filter(appeals, judge_sattyid, aoj_aod_affinity_lever_value,
                                excluded_judges_attorney_ids)

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
  # rubocop:enable Metrics/AbcSize

  def self.generate_nonpriority_case_distribution_lever_aoj_query(aoj_affinity_lever_value)
    if case_affinity_days_lever_value_is_selected?(aoj_affinity_lever_value) ||
       aoj_affinity_lever_value == Constants.ACD_LEVERS.omit
      "((PREV_DECIDING_JUDGE = ? or PREV_DECIDING_JUDGE is null or PREV_DECIDING_JUDGE is not null)
      and AOD = '0' and PREV_TYPE_ACTION <> '7' )"
    elsif aoj_affinity_lever_value == Constants.ACD_LEVERS.infinite
      "(AOD = '0' and PREV_TYPE_ACTION <> '7')"
    else
      "VLJ = ?"
    end
  end

  def self.generate_priority_aoj_case_distribution_lever_query(aoj_cavc_affinity_lever_value)
    if case_affinity_days_lever_value_is_selected?(aoj_cavc_affinity_lever_value) ||
       aoj_cavc_affinity_lever_value == Constants.ACD_LEVERS.omit
      "((PREV_DECIDING_JUDGE = ? or PREV_DECIDING_JUDGE is null or PREV_DECIDING_JUDGE is not null)
      and AOD = '0' and PREV_TYPE_ACTION = '7')"
    elsif aoj_cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite
      "(AOD = '0' and PREV_TYPE_ACTION = '7')"
    else
      "VLJ = ?"
    end
  end

  def self.generate_priority_case_distribution_lever_aoj_aod_query(aoj_aod_affinity_lever_value)
    if case_affinity_days_lever_value_is_selected?(aoj_aod_affinity_lever_value) ||
       aoj_aod_affinity_lever_value == Constants.ACD_LEVERS.omit
      "((PREV_DECIDING_JUDGE = ? or PREV_DECIDING_JUDGE is null or PREV_DECIDING_JUDGE is not null)
      and AOD = '1')"
    elsif aoj_aod_affinity_lever_value == Constants.ACD_LEVERS.infinite
      "(AOD = '1')"
    else
      "VLJ = ?"
    end
  end

  def self.filter_genpop_appeals_for_affinity(query)
    aoj_cavc_affinity_lever_value = CaseDistributionLever.aoj_cavc_affinity_days
    aoj_aod_affinity_lever_value = CaseDistributionLever.aoj_aod_affinity_days
    aoj_affinity_lever_value = CaseDistributionLever.aoj_affinity_days
    excluded_judges_attorney_ids = excluded_judges_sattyids

    conn = connection

    appeals = conn.exec_query(query).to_a

    aoj_affinity_filter(appeals, nil, aoj_affinity_lever_value, excluded_judges_attorney_ids)

    aoj_cavc_affinity_filter(appeals, nil, aoj_cavc_affinity_lever_value, excluded_judges_attorney_ids)

    aoj_aod_affinity_filter(appeals, nil, aoj_aod_affinity_lever_value,
                            excluded_judges_attorney_ids)

    appeals
  end

  # rubocop:disable Metrics/AbcSize
  def self.aoj_affinity_filter(appeals, judge_sattyid, lever_value, excluded_judges_attorney_ids)
    appeals.reject! do |appeal|
      # {will skip if not AOJ AOD || if AOJ AOD being distributed to tied_to judge || if not tied to any judge}
      next if tied_to_or_not_aoj_nonpriority?(appeal, judge_sattyid)

      if not_distributing_to_tied_judge?(appeal, judge_sattyid)
        next if ineligible_judges_sattyids&.include?(appeal["vlj"])

        next (appeal["vlj"] != judge_sattyid)
      end

      if appeal_has_hearing_after_previous_decision?(appeal)
        next if appeal["vlj"] == judge_sattyid
        next true if !ineligible_judges_sattyids.include?(appeal["vlj"])
      end

      next if ineligible_or_excluded_deciding_judge?(appeal, excluded_judges_attorney_ids)

      if case_affinity_days_lever_value_is_selected?(lever_value)
        next if appeal["prev_deciding_judge"] == judge_sattyid

        reject_due_to_affinity?(appeal, lever_value)
      elsif lever_value == Constants.ACD_LEVERS.infinite
        next if deciding_judge_ineligible_with_no_hearings_after_decision(appeal) || appeal["prev_deciding_judge"].nil?

        appeal["prev_deciding_judge"] != judge_sattyid
      elsif lever_value == Constants.ACD_LEVERS.omit
        appeal["prev_deciding_judge"] == appeal["vlj"]
      end
    end
  end

  def self.aoj_cavc_affinity_filter(appeals, judge_sattyid, aoj_cavc_affinity_lever_value, excluded_judges_attorney_ids)
    appeals.reject! do |appeal|
      next if tied_to_or_not_cavc?(appeal, judge_sattyid)

      if not_distributing_to_tied_judge?(appeal, judge_sattyid)
        next if ineligible_judges_sattyids.include?(appeal["vlj"])

        next (appeal["vlj"] != judge_sattyid)
      end

      if appeal_has_hearing_after_previous_decision?(appeal)
        next if appeal["vlj"] == judge_sattyid
        next true if !ineligible_judges_sattyids.include?(appeal["vlj"])
      end

      next if ineligible_or_excluded_deciding_judge?(appeal, excluded_judges_attorney_ids)

      if case_affinity_days_lever_value_is_selected?(aoj_cavc_affinity_lever_value)
        next if appeal["prev_deciding_judge"] == judge_sattyid

        reject_due_to_affinity?(appeal, aoj_cavc_affinity_lever_value)
      elsif aoj_cavc_affinity_lever_value == Constants.ACD_LEVERS.infinite
        next if deciding_judge_ineligible_with_no_hearings_after_decision(appeal) || appeal["prev_deciding_judge"].nil?

        appeal["prev_deciding_judge"] != judge_sattyid
      elsif aoj_cavc_affinity_lever_value == Constants.ACD_LEVERS.omit
        appeal["prev_deciding_judge"] == appeal["vlj"]
      end
    end
  end

  def self.aoj_aod_affinity_filter(appeals, judge_sattyid, lever_value, excluded_judges_attorney_ids)
    appeals.reject! do |appeal|
      # {will skip if not AOJ AOD || if AOJ AOD being distributed to tied_to judge || if not tied to any judge}
      next if tied_to_or_not_aoj_aod?(appeal, judge_sattyid)

      if not_distributing_to_tied_judge?(appeal, judge_sattyid)
        next if ineligible_judges_sattyids&.include?(appeal["vlj"])

        next (appeal["vlj"] != judge_sattyid)
      end

      if appeal_has_hearing_after_previous_decision?(appeal)
        next if appeal["vlj"] == judge_sattyid
        next true if !ineligible_judges_sattyids.include?(appeal["vlj"])
      end

      next if ineligible_or_excluded_deciding_judge?(appeal, excluded_judges_attorney_ids)

      if case_affinity_days_lever_value_is_selected?(lever_value)
        next if appeal["prev_deciding_judge"] == judge_sattyid

        reject_due_to_affinity?(appeal, lever_value)
      elsif lever_value == Constants.ACD_LEVERS.infinite
        next if deciding_judge_ineligible_with_no_hearings_after_decision(appeal) || appeal["prev_deciding_judge"].nil?

        appeal["prev_deciding_judge"] != judge_sattyid
      elsif lever_value == Constants.ACD_LEVERS.omit
        appeal["prev_deciding_judge"] == appeal["vlj"]
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

  def self.tied_to_or_not_aoj_nonpriority?(appeal, judge_sattyid)
    (appeal["prev_type_action"] == "7" || appeal["aod"] == 1) ||
      (appeal["prev_type_action"] != "7" && appeal["aod"] == 0 &&
        !appeal["vlj"].blank? &&
        (appeal["vlj"] == appeal["prev_deciding_judge"] || appeal["prev_deciding_judge"].nil?) &&
        appeal["vlj"] == judge_sattyid) ||
      (appeal["vlj"].nil? && appeal["prev_deciding_judge"].nil?)
  end

  def self.tied_to_or_not_cavc?(appeal, judge_sattyid)
    (appeal["prev_type_action"] != "7" || appeal["aod"] != 0) ||
      (appeal["prev_type_action"] == "7" && appeal["aod"] == 0 &&
        !appeal["vlj"].blank? &&
        (appeal["vlj"] == appeal["prev_deciding_judge"] || appeal["prev_deciding_judge"].nil?) &&
        appeal["vlj"] == judge_sattyid) ||
      (appeal["vlj"].nil? && appeal["prev_deciding_judge"].nil?)
  end

  def self.tied_to_or_not_aoj_aod?(appeal, judge_sattyid)
    (appeal["aod"] != 1) ||
      (appeal["aod"] == 1 &&
        !appeal["vlj"].blank? &&
        (appeal["vlj"] == appeal["prev_deciding_judge"] || appeal["prev_deciding_judge"].nil?) &&
        appeal["vlj"] == judge_sattyid) ||
      (appeal["vlj"].nil? && appeal["prev_deciding_judge"].nil?)
  end

  def self.ineligible_judges_sattyids
    Rails.cache.fetch("case_distribution_ineligible_judges")&.pluck(:sattyid)&.reject(&:blank?) || []
  end

  def self.excluded_judges_sattyids
    VACOLS::Staff.where(sdomainid: JudgeTeam.active
        .where(exclude_appeals_from_affinity: true)
        .flat_map(&:judge).compact.pluck(:css_id))&.pluck(:sattyid)
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/ParameterLists, Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
  def self.priority_appeals_affinity_date_count(in_window)
    conn = connection
    aoj_cavc_affinity_lever_value = CaseDistributionLever.aoj_cavc_affinity_days
    aoj_aod_affinity_lever_value = CaseDistributionLever.aoj_aod_affinity_days

    query = <<-SQL
      #{SELECT_PRIORITY_APPEALS_ORDER_BY_BFD19}
      where (PREV_TYPE_ACTION = '7' or AOD = '1')
    SQL

    fmtd_query = sanitize_sql_array([query])

    appeals = conn.exec_query(fmtd_query).to_a
    if in_window
      appeals.select! do |appeal|
        if appeal["prev_type_action"] == "7" && appeal["aod"] == "0"
          reject_due_to_affinity?(appeal, aoj_cavc_affinity_lever_value)
        else
          reject_due_to_affinity?(appeal, aoj_aod_affinity_lever_value)
        end
      end
    else
      appeals.reject! do |appeal|
        if appeal["prev_type_action"] == "7" && appeal["aod"] == "0"
          reject_due_to_affinity?(appeal, aoj_cavc_affinity_lever_value)
        else
          reject_due_to_affinity?(appeal, aoj_aod_affinity_lever_value)
        end
      end
    end
    appeals
  end
  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity

  def self.non_priority_appeals_affinity_date_count(in_window)
    conn = connection
    aoj_affinity_lever_value = CaseDistributionLever.aoj_affinity_days

    query = <<-SQL
      #{SELECT_NONPRIORITY_APPEALS_ORDER_BY_BFD19}
      where ((PREV_TYPE_ACTION is null or PREV_TYPE_ACTION <> '7') and AOD = '0')
    SQL

    fmtd_query = sanitize_sql_array([query])

    appeals = conn.exec_query(fmtd_query).to_a

    if in_window
      appeals.select! do |appeal|
        reject_due_to_affinity?(appeal, aoj_affinity_lever_value) && !appeal["prev_deciding_judge"].nil? &&
          appeal["prev_deciding_judge"] != appeal["vlj"]
      end
    else
      appeals.reject! do |appeal|
        reject_due_to_affinity?(appeal, aoj_affinity_lever_value) && !appeal["prev_deciding_judge"].nil? &&
          appeal["prev_deciding_judge"] != appeal["vlj"]
      end
    end
    appeals
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
end
