# frozen_string_literal: true

FactoryBot.define do
  factory :cavc_remand do
    sequence(:cavc_docket_number, 9_000) # arbitrary
    represented_by_attorney { true }
    cavc_judge_full_name { Constants::CAVC_JUDGE_FULL_NAMES.first }
    cavc_decision_type { Constants::CAVC_DECISION_TYPES.keys.first }
    remand_subtype { Constants::CAVC_REMAND_SUBTYPES.keys.first }
    decision_date { 30.days.ago.to_date }
    judgement_date { 30.days.ago.to_date }
    mandate_date { 30.days.ago.to_date }
    instructions { "Sample CAVC Remand from factory" }
    created_by { User.first || create(:user) }

    transient do
      judge { JudgeTeam.first&.admin || create(:user).tap { |u| create(:staff, :judge_role, user: u) } }
      attorney do
        JudgeTeam.first&.non_admins&.first ||
          create(:user).tap { |u| create(:staff, :attorney_role, user: u) }
      end
      veteran { Veteran.first || create(:veteran) }
      docket_type { Constants.AMA_DOCKETS.evidence_submission }
    end

    after(:build) do |cavc_remand, evaluator|
      if evaluator.source_appeal
        cavc_remand.source_appeal = evaluator.source_appeal

        cavc_remand.decision_issue_ids = if !evaluator.decision_issue_ids.empty?
                                           evaluator.decision_issue_ids
                                         else
                                           evaluator.source_appeal.decision_issues.pluck(:id)
                                         end
      else
        description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
        notes = "Pain disorder with 100\% evaluation per examination"
        source_appeal = create(:appeal,
                               :dispatched,
                               docket_type: evaluator.docket_type,
                               veteran_file_number: evaluator.veteran.file_number,
                               associated_judge: evaluator.judge,
                               associated_attorney: evaluator.attorney)
        create_list(:request_issue, 2,
                    :rating,
                    :with_rating_decision_issue,
                    decision_review: source_appeal,
                    veteran_participant_id: evaluator.veteran.participant_id,
                    contested_issue_description: description,
                    notes: notes)
        cavc_remand.source_appeal = source_appeal

        cavc_remand.decision_issue_ids = if !evaluator.decision_issue_ids.empty?
                                           evaluator.decision_issue_ids
                                         else
                                           cavc_remand.source_appeal.decision_issues.pluck(:id)
                                         end
      end
    end
  end
end
