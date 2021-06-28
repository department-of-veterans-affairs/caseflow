/* RAILS_EQUIV
JudgeTeam.active.map(&:users).flatten.uniq.count
*/

WITH judge_teams AS (
    SELECT "organizations"."id" FROM "organizations"
    WHERE "organizations"."type" IN ('JudgeTeam') AND "organizations"."status" = 'active'
),
team_users AS (
    SELECT DISTINCT "organizations_users"."user_id", css_id
    FROM "organizations_users"
    JOIN users ON users.id=user_id
    WHERE "organizations_users"."organization_id" IN (select * from judge_teams)
)
SELECT count(*) FROM team_users
