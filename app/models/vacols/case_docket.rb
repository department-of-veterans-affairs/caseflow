class VACOLS::CaseDocket < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.brieff"

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
        where BFMPRO <> 'HIS' and BFAC <> '9' and BFD19 is not null
      )
      group by PRIORITY, READY
    SQL

    connection.exec_query(query)
  end
  # rubocop:enable Metrics/MethodLength

  def self.nod_count
    where("BFMPRO <> 'HIS' and BFAC <> '9' and BFD19 is null")
      .count
  end

  def self.regular_non_aod_docket_count
    joins(VACOLS::Case::JOIN_AOD)
      .where("BFMPRO <> 'HIS' and BFAC in ('1', '3') and BFD19 is not null and AOD = 0")
      .count
  end

  def self.docket_date_of_nth_appeal_in_case_storage(n)
    query = <<-SQL
      select BFD19 from (
        select row_number() over (order by BFD19 asc) as ROWNUMBER,
          BFD19
        from BRIEFF
        where BFCURLOC in ('81', '83')
          and BFAC <> '9'
      )
      where ROWNUMBER = ?
    SQL

    connection.exec_query(sanitize_sql_array([query, n])).first["bfd19"].to_date
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

  def self.oldest_priority_appeal_ready_date
    joins(VACOLS::Case::JOIN_AOD)
      .where("BFMPRO <> 'HIS' and BFCURLOC in ('81', '83') and (BFAC = '7' or AOD = 1)")
      .minimum(:bfdloout)
  end
  # :nocov:
end
