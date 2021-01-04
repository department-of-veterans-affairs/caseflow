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

    after(:build) do |cavc_remand, evaluator|
      cavc_remand.created_by = (evaluator.created_by || User.first)

      if evaluator.appeal
        cavc_remand.appeal = evaluator.appeal

        cavc_remand.decision_issue_ids = if !evaluator.decision_issue_ids.empty?
                                           evaluator.decision_issue_ids
                                         else
                                           evaluator.appeal.decision_issues.pluck(:id)
                                         end
      else
        judge = JudgeTeam.first.admin
        attorney = JudgeTeam.first.non_admins.first
        veteran = Veteran.first

        description = "Service connection for pain disorder is granted with an evaluation of 70\% effective May 1 2011"
        notes = "Pain disorder with 100\% evaluation per examination"
        appeal = create(:appeal,
                        :dispatched,
                        veteran_file_number: veteran.file_number,
                        associated_judge: judge,
                        associated_attorney: attorney)
        create_list(:request_issue, 2,
                    :rating,
                    :with_rating_decision_issue,
                    decision_review: appeal,
                    veteran_participant_id: veteran.participant_id,
                    contested_issue_description: description,
                    notes: notes)
        cavc_remand.appeal = appeal

        cavc_remand.decision_issue_ids = if !evaluator.decision_issue_ids.empty?
                                           evaluator.decision_issue_ids
                                         else
                                           cavc_remand.appeal.decision_issues.pluck(:id)
                                         end
      end
    end
  end
end
