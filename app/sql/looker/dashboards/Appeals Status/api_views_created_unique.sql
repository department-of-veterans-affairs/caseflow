-- raw sql results do not include filled-in values for 'api_views.created_month'
-- NOT WORKING

WITH legacy_veterans AS (SELECT 
	legacy_appeals.vbms_id  AS vbms_id,
	COUNT(*) AS count
FROM public.legacy_appeals  AS legacy_appeals

GROUP BY 1)
SELECT 
	TO_CHAR(DATE_TRUNC('month', api_views.created_at ), 'YYYY-MM') AS "api_views.created_month",
	COUNT(DISTINCT api_views.vbms_id ) AS "api_views.unique_veterans"
FROM public.api_views  AS api_views
LEFT JOIN public.api_keys  AS api_keys ON api_views.api_key_id = api_keys.id 
LEFT JOIN legacy_veterans ON api_views.vbms_id = legacy_veterans.vbms_id 

WHERE (api_views.created_at  >= TIMESTAMP '2018-03-21 11:00') AND ((api_views.created_at  < (DATEADD(month,0, DATE_TRUNC('month', DATE_TRUNC('day',GETDATE())) )))) AND (api_keys.consumer_name = 'Vets.gov') AND (legacy_veterans.count > 0)
GROUP BY DATE_TRUNC('month', api_views.created_at )
ORDER BY 1 DESC
LIMIT 500