WITH vacols_folder AS (SELECT *,
    (select count(*) into dcnt from vacols.assign where tsktknm = vf.ticknum and tskactcd in ('B', 'B1', 'B2')) +
      (select count(*) into hcnt from vacols.hearsched where folder_nr = vf.ticknum and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y')) as AOD
    from vacols.folder vf )
  ,  vacols_brieff AS (select *, ((select count(*) into dcnt from vacols.assign
            where tsktknm = bf.bfkey  and tskactcd in ('B', 'B1', 'B2')
        ) +
        (select count(*) into hcnt from vacols.hearsched where folder_nr = bf.bfkey
          and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y'))
        ) as aod_count
         from vacols.brieff bf
        )
SELECT 
	DATE(vacols_brieff."BFD19" ) AS "vacols_brieff.bfd19_date",
	DATE(vacols_brieff."BF41STAT" ) AS "vacols_brieff.bf41_stat_date",
	DATE(vacols_brieff."BFDDEC" ) AS "vacols_brieff.bfddec_date",
	DATE(vacols_folder.tidrecv ) AS "vacols_folder.tidrecv_date",
	vacols_brieff."BFHA"  AS "vacols_brieff.bfha",
	vacols_folder.AOD AS "vacols_folder.aod_cnt"
FROM vacols_folder
LEFT JOIN vacols_brieff ON (vacols_brieff."BFKEY") = vacols_folder.ticknum 

WHERE (((vacols_brieff."BFAC") = '1')) AND ((vacols_brieff."BFDC"  IN ('1', '2', '3', '4', '5', '6', '7', '8', '9'))) AND ((((vacols_brieff."BFDDEC" ) >= ((DATE(DATEADD(day,-99, DATE_TRUNC('day',GETDATE()) )))) AND (vacols_brieff."BFDDEC" ) < ((DATE(DATEADD(day,100, DATEADD(day,-99, DATE_TRUNC('day',GETDATE()) ) )))))))
GROUP BY 1,2,3,4,5,6
ORDER BY 1 DESC
LIMIT 500