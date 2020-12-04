/* RAILS_EQUIV
start_time=(Date.current-60.months).strftime("%Y-%m")
res=VACOLS::CaseDocket.
  where(BFDC: ['1', '3', '4', '6']).
  where("to_char(BFDDEC,'YYYY-MM') > '#{start_time}'").
  group("to_char(BFDDEC,'YYYY-MM')").
  count
array_output=res.sort
*/

-- SQL_DB_CONNECTION: VACOLS::Case

SELECT to_char(BFDDEC,'YYYY-MM') AS month, count(*) as count
FROM (
    SELECT *
    FROM VACOLS.BRIEFF
    WHERE BRIEFF.BFDC IN ('1', '3', '4', '6')
      AND BFDDEC >= ADD_MONTHS(CURRENT_DATE, -60)
    --ORDER BY         case when to_char(BFDDEC,'YYYY') > '2018' then 1 else 0 end
)
GROUP BY to_char(BFDDEC,'YYYY-MM')
ORDER BY to_char(BFDDEC,'YYYY-MM')
