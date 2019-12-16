WITH max_nonpriority_not_genpop_docket_index AS (select distinct d_id, coalesce, id, case_id from (select t.d_id, t.coalesce, m.id, m.case_id from(SELECT distributions.id as d_id, coalesce(max(distributed_cases.docket_index),0)
           FROM public.distributions as distributions
           LEFT OUTER JOIN public.distributed_cases as distributed_cases ON (distributed_cases.distribution_id = distributions.id
           and distributed_cases.priority='false' and distributed_cases.genpop_query='not_genpop')
           group by 1 order by 1) t LEFT OUTER JOIN distributed_cases m ON m.distribution_id = t.d_id AND t.coalesce = m.docket_index  order by d_id) )
  ,  max_nonpriority_any_docket_index AS (select distinct d_id, coalesce, id, case_id from (select t.d_id, t.coalesce, m.id, m.case_id from(SELECT distributions.id as d_id, coalesce(max(distributed_cases.docket_index),0)
           FROM public.distributions as distributions
           LEFT OUTER JOIN public.distributed_cases as distributed_cases ON (distributed_cases.distribution_id = distributions.id
           and distributed_cases.priority='false' and distributed_cases.genpop_query='any')
           group by 1 order by 1) t LEFT OUTER JOIN distributed_cases m ON m.distribution_id = t.d_id AND t.coalesce = m.docket_index  order by d_id) )
  ,  vacols_folder_not_genpop_cases AS (SELECT *,
          (select count(*) into dcnt from vacols.assign where tsktknm = vf.ticknum and tskactcd in ('B', 'B1', 'B2')) +
            (select count(*) into hcnt from vacols.hearsched where folder_nr = vf.ticknum and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y')) as AOD
          from vacols.folder vf )
  ,  vacols_folder_any_cases AS (SELECT *,
          (select count(*) into dcnt from vacols.assign where tsktknm = vf.ticknum and tskactcd in ('B', 'B1', 'B2')) +
            (select count(*) into hcnt from vacols.hearsched where folder_nr = vf.ticknum and hearing_type in ('C', 'T', 'V') and aod in ('G', 'Y')) as AOD
          from vacols.folder vf )
SELECT 
	distributions.id  AS "distributions.id",
	max_nonpriority_any_docket_index.coalesce AS "max_nonpriority_any_docket_index.docket_index",
	max_nonpriority_not_genpop_docket_index.coalesce AS "max_nonpriority_not_genpop_docket_index.docket_index",
	vacols_folder_not_genpop_cases.tinum  AS "vacols_folder_not_genpop_cases.tinum",
	vacols_folder_any_cases.tinum  AS "vacols_folder_any_cases.tinum",
	COUNT(CASE WHEN (distributed_cases.priority = 'false') AND (distributed_cases.genpop_query LIKE 'not_genpop') THEN 1 ELSE NULL END) AS "distributed_cases.not_genpop_non_priority_count"
FROM public.distributions  AS distributions
LEFT JOIN public.distributed_cases  AS distributed_cases ON distributions.id = distributed_cases.distribution_id 
LEFT JOIN max_nonpriority_not_genpop_docket_index ON max_nonpriority_not_genpop_docket_index.d_id = distributions.id 
LEFT JOIN max_nonpriority_any_docket_index ON max_nonpriority_any_docket_index.d_id = distributions.id 
LEFT JOIN vacols_folder_not_genpop_cases ON max_nonpriority_not_genpop_docket_index.case_id = vacols_folder_not_genpop_cases.ticknum 
LEFT JOIN vacols_folder_any_cases ON max_nonpriority_any_docket_index.case_id = vacols_folder_any_cases.ticknum 

GROUP BY 1,2,3,4,5
ORDER BY 1 
LIMIT 500