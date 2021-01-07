/* RAILS_EQUIV
start_time=Time.utc(2016, 10, 1, 4)
res=BvaDispatchTask.completed.where("closed_at > ?", start_time).order(:closed_at).group_by{|t|
  [(t.closed_at + 3.months).beginning_of_year, t.appeal_type, t.appeal_id]
}.keys;
res2=res.group_by{|month, appeal_type, appeal_id| [month.strftime("FY%y"), appeal_type] };
res3=res2.map{|key, appeals| [key.first, key.second, appeals.count]};
array_output=res3.sort_by{|k,v| k}
*/

select to_char(year,'"FY"YY') as FY, appeal_type, count(*) 
FROM (
    SELECT 
        DATE_TRUNC('year', closed_at + INTERVAL '3 months') AS year
        , appeal_type ,appeal_id
    FROM tasks 
    WHERE type IN ('BvaDispatchTask') 
        AND status = 'completed' 
        AND closed_at > '2016-10-01 04:00:00'
    GROUP BY appeal_id, appeal_type, year
) as subq
GROUP BY 1, 2
ORDER BY 1, 2
