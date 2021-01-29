class BackfillJudgeTeamAcceptsPriorityPushedCases < ActiveRecord::Migration[5.2]
 disable_ddl_transaction!

 def change
   JudgeTeam.active.in_batches do |relation|
       relation.update_all accepts_priority_pushed_cases: true
       sleep(0.1)
   end
 end
end
