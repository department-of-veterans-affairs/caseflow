# frozen_string_literal: true

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
      appeal { create(:appeal, :assigned_to_judge) }
    end

    factory :legacy_distributed_case do
      case_id { appeal.bfkey }
      distribution { create(:distribution, judge: create(:user, :judge, :with_vacols_judge_record)) }
      docket { LegacyDocket.docket_type }
      docket_index { rand(1..100) }
      priority { nil }
      ready_at { appeal.bfdloout }
      sct_appeal { false }
      task { nil }
      genpop { false }
      genpop_query { "any" }
    end
  end
end
