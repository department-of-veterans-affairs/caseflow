# frozen_string_literal: true

describe Events::DecisionReviewCreate::UpdatedVacolsOnOptin do
  context "#Update" do
    let(:user) { Generators::User.build }
    let(:veteran_file_number) { "64205050" }
    let!(:event1) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
    # HLR
    let!(:higher_level_review) { HigherLevelReview.new(veteran_file_number: veteran_file_number) }
    let!(:higher_level_review_event_record) do
      EventRecord.create!(event: event1, backfill_record: higher_level_review)
    end
    # Request Issue
    let!(:request_issue) { RequestIssue.new(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "vacols333", vacols_sequence_id: 1) }
    let!(:request_issue_event_record) { EventRecord.create!(event: event1, backfill_record: request_issue) }
    # Legacy Issue
    let!(:legacy_issue) { LegacyIssue.new(request_issue_id: request_issue.id, vacols_id: "vacols111", vacols_sequence_id: 1) }
    let!(:legacy_issue_event_record) { EventRecord.create!(event: event1, backfill_record: legacy_issue) }
    # Legacy Issue Optin
    let!(:legacy_issue_optin) { LegacyIssueOptin.new(request_issue_id: request_issue.id) }
    let!(:legacy_issue_optin_event_record) do
      EventRecord.create!(event: event1, backfill_record: legacy_issue_optin)
    end

    subject { Events::DecisionReviewCreate::UpdatedVacolsOnOptin.update!(higher_level_review) }
    it "Updates with the request_issue" do
      RequestStore.store[:current_user] = user

      veteran_file_number = "872958715"

      # HLR.ID = 289
      higher_level_review = HigherLevelReview.create!(veteran_file_number: veteran_file_number, benefit_type: "compensation")
      # request_issue.id 5364
      request_issue2 = RequestIssue.create!(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "LEGACYID", vacols_sequence_id: 2)
      request_issue3 = RequestIssue.create!(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "LEGACYID", vacols_sequence_id: 3)
      request_issue4 = RequestIssue.create!(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "LEGACYID", vacols_sequence_id: 4)
      request_issue5 = RequestIssue.create!(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "LEGACYID", vacols_sequence_id: 5)

      # LegacyAppeal.create!(vacols_id: "vacols333")
      LegacyIssue.create!(request_issue_id: request_issue2.id, vacols_id: "LEGACYID", vacols_sequence_id: 2)
      LegacyIssue.create!(request_issue_id: request_issue3.id, vacols_id: "LEGACYID", vacols_sequence_id: 3)
      LegacyIssue.create!(request_issue_id: request_issue4.id, vacols_id: "LEGACYID", vacols_sequence_id: 4)
      LegacyIssue.create!(request_issue_id: request_issue5.id, vacols_id: "LEGACYID", vacols_sequence_id: 5)

      LegacyIssueOptin.create!(request_issue_id: request_issue2.id)
      LegacyIssueOptin.create!(request_issue_id: request_issue3.id)
      LegacyIssueOptin.create!(request_issue_id: request_issue4.id)
      LegacyIssueOptin.create!(request_issue_id: request_issue5.id)


      subject
    end

  end
end
