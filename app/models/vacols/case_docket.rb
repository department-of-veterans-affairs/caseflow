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
    where("BFMPRO <> 'HIS' and BFAC <> '9' and BFD19 is null").count
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

  # rubocop:disable Metrics/MethodLength
  def self.distribute_nonpriority_appeals(judge, genpop, range, limit)
    conn = connection

    query = <<-SQL
      select BFKEY, BFD19, VLJ, DOCKET_INDEX
      from (
        select BFKEY, BFD19, rownum DOCKET_INDEX,
          case when BFHINES is null or BFHINES <> 'GP' then VLJ_HEARINGS.VLJ end VLJ
        from (
          select BFKEY, BFD19, BFMPRO, BFCURLOC, BFHINES
          from (
            select BFKEY, BFD19, BFMPRO, BFCURLOC, BFAC, BFHINES,
              case when nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0) > 0 then 1 else 0 end AOD
            from BRIEFF
            left join (
              select TSKTKNM, count(*) CNT
              from ASSIGN
              where TSKACTCD in ('B', 'B1', 'B2')
              group by TSKTKNM
            ) AOD_DIARIES on AOD_DIARIES.TSKTKNM = BRIEFF.BFKEY
            left join (
              select FOLDER_NR, count(*) CNT
              from HEARSCHED
              where HEARING_TYPE in ('C', 'T', 'V')
                and AOD in ('G', 'Y')
              group by FOLDER_NR
            ) AOD_HEARINGS on AOD_HEARINGS.FOLDER_NR = BRIEFF.BFKEY
          ) BRIEFF
          where BRIEFF.BFMPRO <> 'HIS' and BRIEFF.BFCURLOC in ('81', '83')
            and BFAC <> '7' and AOD = '0'
          order by BFD19
        ) BRIEFF
        inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
        left join (
          select distinct TITRNUM, TINUM,
            first_value(BOARD_MEMBER) over (partition by TITRNUM, TINUM order by HEARING_DATE desc) VLJ
          from HEARSCHED
          inner join FOLDER on FOLDER.TICKNUM = HEARSCHED.FOLDER_NR
          where HEARING_TYPE in ('C', 'T', 'V') and HEARING_DISP = 'H'
        ) VLJ_HEARINGS
          on VLJ_HEARINGS.VLJ not in ('000', '888', '999')
            and VLJ_HEARINGS.TITRNUM = FOLDER.TITRNUM
            and (VLJ_HEARINGS.TINUM is null or VLJ_HEARINGS.TINUM = FOLDER.TINUM)
      )
      where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and (DOCKET_INDEX <= ? or 1 = ?)
        and rownum <= ?;
    SQL

    conn.transaction do
      conn.execute("lock BRIEFF in row exclusive mode")
      appeals = conn.exec_query(sanitize_sql_array([
                                                     query,
                                                     judge.vacols_attorney_id,
                                                     (genpop.nil? || !genpop) ? 1 : 0,
                                                     (genpop.nil? || genpop) ? 1 : 0,
                                                     range,
                                                     limit
                                                   ])).to_hash
      vacols_ids = appeals.map { |appeal| appeal["bfkey"] }
      batch_update_vacols_location(conn, judge.vacols_uniq_id, vacols_ids)
      appeals
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def self.distribute_priority_appeals(judge, genpop, limit)
    conn = connection

    query = <<-SQL
      select BFKEY, BFDLOOUT, VLJ
      from (
        select BFKEY, BFDLOOUT,
          case when BFHINES is null or BFHINES <> 'GP' then nvl(VLJ_HEARINGS.VLJ, VLJ_PRIORDEC.VLJ) end VLJ
        from (
          select BFKEY, BFDLOOUT, BFMPRO, BFCURLOC, BFHINES, AOD
          from (
            select BFKEY, BFDLOOUT, BFMPRO, BFCURLOC, BFAC, BFHINES,
              case when nvl(AOD_DIARIES.CNT, 0) + nvl(AOD_HEARINGS.CNT, 0) > 0 then 1 else 0 end AOD
            from BRIEFF
            left join (
              select TSKTKNM, count(*) CNT
              from ASSIGN
              where TSKACTCD in ('B', 'B1', 'B2')
              group by TSKTKNM
            ) AOD_DIARIES on AOD_DIARIES.TSKTKNM = BRIEFF.BFKEY
            left join (
              select FOLDER_NR, count(*) CNT
              from HEARSCHED
              where HEARING_TYPE in ('C', 'T', 'V')
                and AOD in ('G', 'Y')
              group by FOLDER_NR
            ) AOD_HEARINGS on AOD_HEARINGS.FOLDER_NR = BRIEFF.BFKEY
          ) BRIEFF
          where BRIEFF.BFMPRO <> 'HIS' and BRIEFF.BFCURLOC in ('81', '83')
            and (BFAC = '7' or AOD = '1')
          order by BFDLOOUT
        ) BRIEFF
        inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
        left join (
          select distinct TITRNUM, TINUM,
            first_value(BOARD_MEMBER) over (partition by TITRNUM, TINUM order by HEARING_DATE desc) VLJ
          from HEARSCHED
          inner join FOLDER on FOLDER.TICKNUM = HEARSCHED.FOLDER_NR
          where HEARING_TYPE in ('C', 'T', 'V') and HEARING_DISP = 'H'
        ) VLJ_HEARINGS
          on VLJ_HEARINGS.VLJ not in ('000', '888', '999')
            and VLJ_HEARINGS.TITRNUM = FOLDER.TITRNUM
            and (VLJ_HEARINGS.TINUM is null or VLJ_HEARINGS.TINUM = FOLDER.TINUM)
        left join (
          select distinct TITRNUM, TINUM,
            first_value(BFMEMID) over (partition by TITRNUM, TINUM order by BFDDEC desc) VLJ
          from BRIEFF
          inner join FOLDER on FOLDER.TICKNUM = BRIEFF.BFKEY
          where BFATTID is not null and BFMEMID not in ('000', '888', '999')
        ) VLJ_PRIORDEC
          on BRIEFF.AOD = 1
            and VLJ_HEARINGS.VLJ is null
            and VLJ_PRIORDEC.TITRNUM = FOLDER.TITRNUM
            and (VLJ_PRIORDEC.TINUM is null or VLJ_PRIORDEC.TINUM = FOLDER.TINUM)
      )
      where ((VLJ = ? and 1 = ?) or (VLJ is null and 1 = ?))
        and rownum <= ?;
    SQL

    conn.transaction do
      conn.execute("lock BRIEFF in row exclusive mode")
      appeals = conn.exec_query(sanitize_sql_array([
                                                     query,
                                                     judge.vacols_attorney_id,
                                                     (genpop.nil? || !genpop) ? 1 : 0,
                                                     (genpop.nil? || genpop) ? 1 : 0,
                                                     limit
                                                   ])).to_hash
      vacols_ids = appeals.map { |appeal| appeal["bfkey"] }
      batch_update_vacols_location(conn, judge.vacols_uniq_id, vacols_ids)
      appeals
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  # rubocop:disable Metrics/MethodLength
  def batch_update_vacols_location(conn, location, vacols_ids)
    user_id = (RequestStore.store[:current_user].vacols_uniq_id || "DSUSER").upcase

    conn.execute(sanitize_sql_array([<<-SQL, location, vacols_ids]))
      update BRIEFF
      set BFDLOCIN = SYSDATE,
          BFCURLOC = ?,
          BFDLOOUT = SYSDATE,
          BFORGTIC = NULL
      where BFKEY in (?)
    SQL

    conn.execute(sanitize_sql_array([<<-SQL, user_id, vacols_ids]))
      update PRIORLOC
      set LOCDIN = SYSDATE,
          LOCSTRCV = ?,
          LOCEXCEP = 'Y'
      where LOCKEY in (?) and LOCDIN is null
    SQL

    insert_strs = vacols_ids.map do |vacols_id|
      sanitize_sql_array(
        [
          "into PRIORLOC (LOCDOUT, LOCDTO, LOCSTTO, LOCSTOUT, LOCKEY) values (SYSDATE, SYSDATE, ?, ?, ?)",
          location,
          user_id,
          vacols_id
        ]
      )
    end

    conn.execute("insert all #{insert_strs.join(' ')} select 1 from dual")
  end
  # rubocop:enable Metrics/MethodLength
  # :nocov:
end
