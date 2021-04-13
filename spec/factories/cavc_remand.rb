# frozen_string_literal: true

FactoryBot.define do
  factory :cavc_remand do
    sequence(:cavc_docket_number, 1000) { |n| "12-#{n}" } # arbitrary
    represented_by_attorney { true }
    cavc_judge_full_name { Constants::CAVC_JUDGE_FULL_NAMES.first }
    cavc_decision_type { Constants::CAVC_DECISION_TYPES["remand"] }
    remand_subtype { Constants::CAVC_REMAND_SUBTYPES["jmr"] }
    decision_date { 30.days.ago.to_date }
    judgement_date { 30.days.ago.to_date }
    mandate_date { 30.days.ago.to_date }
    federal_circuit { (remand_subtype == Constants::CAVC_REMAND_SUBTYPES["mdr"]) ? false : nil }
    instructions { "Sample CAVC Remand from factory" }
    created_by { User.first || create(:user) }
    updated_by { User.first || create(:user) }

    transient do
      judge { JudgeTeam.first&.admin || create(:user).tap { |u| create(:staff, :judge_role, user: u) } }
      attorney do
        JudgeTeam.first&.non_admins&.first ||
          create(:user).tap { |u| create(:staff, :attorney_role, user: u) }
      end
      veteran { create(:veteran) }
      docket_type { Constants.AMA_DOCKETS.evidence_submission }
      decision_issues_selected_count { nil }
    end

    after(:build) do |cavc_remand, evaluator|
      if evaluator.source_appeal
        cavc_remand.source_appeal = evaluator.source_appeal

        cavc_remand.decision_issue_ids = if evaluator.decision_issues_selected_count
                                           evaluator.source_appeal.decision_issues
                                             .first(evaluator.decision_issues_selected_count).pluck(:id)
                                         elsif !evaluator.source_appeal.decision_issues.empty?
                                           evaluator.source_appeal.decision_issues.pluck(:id)
                                         else
                                           FactoryBotHelper.create_issues_for(evaluator.source_appeal)
                                           evaluator.source_appeal.decision_issues.pluck(:id)
                                         end
      else
        cavc_remand.source_appeal = create(:appeal,
                                           :dispatched,
                                           docket_type: evaluator.docket_type,
                                           veteran_file_number: evaluator.veteran.file_number,
                                           associated_judge: evaluator.judge,
                                           associated_attorney: evaluator.attorney)
        FactoryBotHelper.create_issues_for(cavc_remand.source_appeal)
        cavc_remand.source_appeal.reload.decision_issues.each_with_index do |di, i|
          di.description += " ##{i + 1}"
          di.save!
        end

        cavc_remand.decision_issue_ids = if evaluator.decision_issues_selected_count
                                           cavc_remand.source_appeal.decision_issues
                                             .first(evaluator.decision_issues_selected_count).pluck(:id)
                                         else
                                           cavc_remand.source_appeal.decision_issues.pluck(:id)
                                         end
      end
    end

    trait :mdr do
      no_mandate
      remand_subtype { Constants::CAVC_REMAND_SUBTYPES["mdr"] }
    end

    trait :jmr do
      remand_subtype { Constants::CAVC_REMAND_SUBTYPES["jmr"] }
    end

    trait :jmpr do
      remand_subtype { Constants::CAVC_REMAND_SUBTYPES["jmpr"] }
    end

    trait :straight_reversal do
      cavc_decision_type { Constants::CAVC_DECISION_TYPES["straight_reversal"] }
      remand_subtype { nil }
    end

    trait :death_dismissal do
      cavc_decision_type { Constants::CAVC_DECISION_TYPES["death_dismissal"] }
      remand_subtype { nil }
    end

    trait :no_mandate do
      judgement_date { nil }
      mandate_date { nil }
    end
  end

  module FactoryBotHelper
    def self.create_issues_for(appeal)
      description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
      notes = "Pain disorder with 100\% evaluation per examination"
      issues_mapping = FactoryBot.create_list(:request_issue, 3,
                                              :rating,
                                              :with_rating_decision_issue,
                                              decision_review: appeal,
                                              veteran_participant_id: appeal.veteran.participant_id,
                                              contested_issue_description: description,
                                              notes: notes).zip(appeal.decision_issues)
      issues_mapping.each { |req_issue, dec_issue| req_issue.decision_issues << dec_issue }
    end
  end
end
