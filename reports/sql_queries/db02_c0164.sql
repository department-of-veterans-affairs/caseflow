/* RAILS_EQUIV
grouped_appeals = Appeal.all.group_by{|a| [a.created_at.beginning_of_month, a.stream_type]}
result_table = grouped_appeals.map{|key, appeals| [key.first.strftime("%Y-%m-%d"), key.second, appeals.count]};
array_output=result_table.sort_by{|month,stream,count| [month,stream]}
*/

SELECT
    to_char(DATE_TRUNC('month', created_at), 'YYYY-MM-DD') AS month,
    stream_type,
    COUNT(*) AS count
FROM appeals
GROUP BY 1, 2
ORDER BY 1, 2
