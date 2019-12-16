WITH vacols_decass AS (select *, (select p.locdin from VACOLS.PRIORLOC p WHERE p.lockey=de.defolder AND p.locstto = '81' ORDER BY p.locdin DESC LIMIT 1) as distribution_date    from VACOLS.DECASS de )
SELECT 
	vacols_decass."DEFOLDER"  AS "vacols_decass.defolder",
	DATE(vacols_decass."DEADTIM" ) AS "vacols_decass.deadtim_date",
	COUNT(*) AS "vacols_decass.count"
FROM vacols_decass

GROUP BY 1,2
HAVING 
	(COUNT(*) > 2)
ORDER BY 2 DESC
LIMIT 500