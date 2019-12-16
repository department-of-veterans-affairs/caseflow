SELECT * FROM (SELECT
	COUNT(*) AS "vacols_raw_issues.count"
FROM VACOLS.ISSUES   vacols_raw_issues
) WHERE ROWNUM <= 500