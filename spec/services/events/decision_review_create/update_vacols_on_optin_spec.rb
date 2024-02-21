# frozen_string_literal: true

describe Events::DecisionReviewCreate::UpdateVacolsOnOptin do
  let(:user) { Generators::User.build }
  let(:veteran_file_number) { "64205050" }
  # mock VACOLS issue and cases
  let!(:vacols_issue1) { create(:case_issue, :compensation, issseq: 1) }
  let!(:vacols_issue2) { create(:case_issue, :compensation, issseq: 2) }
  let!(:vacols_issue3) { create(:case_issue, :compensation, issseq: 3) }
  let!(:vacols_case) do
    create(:case, :status_active, bfcurloc: "77", bfkey: "DRCTEST",
           case_issues: [vacols_issue1, vacols_issue2, vacols_issue3])
  end

  let!(:event1) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
  # HLR
  let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: veteran_file_number) }
  let!(:higher_level_review_event_record) do
    EventRecord.create!(event: event1, backfill_record: higher_level_review)
  end
  # Event Record Request Issue
  let!(:request_issue1) { RequestIssue.new(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "DRCTEST", vacols_sequence_id: 1) }
  let!(:request_issue_event_record1) { EventRecord.create!(event: event1, backfill_record: request_issue1) }
  let!(:request_issue2) { RequestIssue.new(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "DRCTEST", vacols_sequence_id: 2) }
  let!(:request_issue_event_record2) { EventRecord.create!(event: event1, backfill_record: request_issue2) }
  let!(:request_issue3) { RequestIssue.new(benefit_type: "compensation", decision_review: higher_level_review, vacols_id: "DRCTEST", vacols_sequence_id: 3) }
  let!(:request_issue_event_record3) { EventRecord.create!(event: event1, backfill_record: request_issue3) }
  # Legacy Issue
  let!(:legacy_issue1) { LegacyIssue.new(request_issue_id: request_issue1.id, vacols_id: "DRCTEST", vacols_sequence_id: 1) }
  let!(:legacy_issue_event_record1) { EventRecord.create!(event: event1, backfill_record: legacy_issue1) }
  let!(:legacy_issue2) { LegacyIssue.new(request_issue_id: request_issue2.id, vacols_id: "DRCTEST", vacols_sequence_id: 2) }
  let!(:legacy_issue_event_record2) { EventRecord.create!(event: event1, backfill_record: legacy_issue2) }
  let!(:legacy_issue3) { LegacyIssue.new(request_issue_id: request_issue3.id, vacols_id: "DRCTEST", vacols_sequence_id: 3) }
  let!(:legacy_issue_event_record3) { EventRecord.create!(event: event1, backfill_record: legacy_issue3) }
  # Legacy Issue Optin
  let!(:legacy_issue_optin1) { LegacyIssueOptin.new(request_issue_id: request_issue1.id) }
  let!(:legacy_issue_optin_event_record1) do
    EventRecord.create!(event: event1, backfill_record: legacy_issue_optin1)
  end
  let!(:legacy_issue_optin2) { LegacyIssueOptin.new(request_issue_id: request_issue2.id) }
  let!(:legacy_issue_optin_event_record2) do
    EventRecord.create!(event: event1, backfill_record: legacy_issue_optin2)
  end
  let!(:legacy_issue_optin3) { LegacyIssueOptin.new(request_issue_id: request_issue3.id) }
  let!(:legacy_issue_optin_event_record3) do
    EventRecord.create!(event: event1, backfill_record: legacy_issue_optin3)
  end
  def vacols_issue(vacols_id, vacols_sequence_id)
    # Use this instead of reload for VACOLS issues, because reload mutates the issseq
    VACOLS::CaseIssue.find_by(isskey: vacols_id, issseq: vacols_sequence_id)
  end
  subject { Events::DecisionReviewCreate::UpdateVacolsOnOptin.perform!(higher_level_review) }
  context "#perform!" do
    before do
      RequestStore.store[:current_user] = user
    end
    it "Does not run perform if SOC/SSOC is not approved" do
      subject
      expect(subject).to be_nil
    end
    it "Updates VACOLS ISSUE Dispostition Code" do
      higher_level_review.update!(legacy_opt_in_approved: true)
      subject
      expect(vacols_issue("DRCTEST", 1).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
      expect(vacols_issue("DRCTEST", 2).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
      expect(vacols_issue("DRCTEST", 3).issdc).to eq(LegacyIssueOptin::VACOLS_DISPOSITION_CODE)
      expect(vacols_case.reload).to be_closed
    end
  end
end
