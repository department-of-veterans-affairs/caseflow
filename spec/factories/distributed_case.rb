# frozen_string_literal: true

# This factory will create a DistributedCase with the required fields based on an appeal
FactoryBot.define do
  factory :distributed_case do
    case_id { appeal.uuid }
    distribution { create(:distribution, judge: create(:user, :judge, :with_vacols_judge_record)) }
    docket { appeal.docket_type }
    docket_index { nil }
    priority { (appeal.aod? || appeal.cavc?) }
    ready_at { appeal.tasks.find_by(type: DistributionTask.name).assigned_at }
    sct_appeal { appeal.sct_appeal? }
    task { appeal.tasks.find_by(type: JudgeAssignTask.name) || create(:ama_judge_assign_task, appeal: appeal) }
    genpop { true if appeal.docket_type == "hearing" }
    genpop_query { "only_genpop" if appeal.docket_type == "hearing" }

    transient do
      # There is a callback to create an AppealState record for appeal_docketed that will raise an error without this
      RequestStore[:current_user] ||= User.system_user

      appeal { create(:appeal, :assigned_to_judge) }
    end
  end
end
