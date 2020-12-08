
/* RAILS_EQUIV
time_start=Time.utc(2018, 10, 1, 4)
res=BvaDispatchTask.completed.where("closed_at > ?", time_start).order(:closed_at).group_by{|t|
  [t.closed_at.beginning_of_month, t.appeal_type, t.appeal_id]
}.keys;
res2=res.group_by{|month, appeal_type, appeal_id| [month.strftime("%Y-%m-%d"), appeal_type] };
res3=res2.map{|key, appeals| [key.first, key.second, appeals.count]};
array_output=res3.sort_by{|k,v| k}
*/

select to_char(month, 'YYYY-MM-DD') AS month, appeal_type, count(*) 
FROM (
    SELECT 
        DATE_TRUNC('month', closed_at) AS month, -- does not consider time zone; uses UTC timestamp
        appeal_type, appeal_id
    FROM tasks 
    WHERE type IN ('BvaDispatchTask') 
        AND status = 'completed' 
        AND closed_at > '2018-10-01 04:00:00'
    GROUP BY appeal_id, appeal_type, month
) as subq
GROUP BY 1, 2
ORDER BY 1, 2
