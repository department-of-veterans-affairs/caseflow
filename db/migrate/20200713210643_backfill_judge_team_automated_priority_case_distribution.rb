class BackfillJudgeTeamAutomatedPriorityCaseDistribution < ActiveRecord::Migration[5.2]
 disable_ddl_transaction!

 def change
   JudgeTeam.active.in_batches do |relation|
       relation.update_all automated_priority_case_distribution: true
       sleep(0.1)
   end
 end
end
