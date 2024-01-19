# frozen_string_literal: true

describe EventRecord, :postgres do
  context "One Event with One Event Record with One Intake" do
    let(:user) { Generators::User.build }
    let(:veteran_file_number) { "64205050" }
    let!(:event1) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
    let!(:intake) { Intake.create!(veteran_file_number: veteran_file_number, user: user) }
    let!(:intake_event_record) { EventRecord.create!(event_id: event1.id, backfill_record: intake) }
    it "Event Record backfill ID and type match Intake ID and type" do
      expect(intake_event_record.backfill_record_type).to eq("Intake")
      expect(intake_event_record.backfill_record_id).to eq(intake.id)
      expect(intake.event_records.count).to eq 1
    end
  end
  context "One Event with 10 Different Event Records" do
    let(:veteran_file_number) { "64205050" }
    let!(:event2) { DecisionReviewCreatedEvent.create!(reference_id: "2") }
    # HLR
    let!(:higher_level_review) { HigherLevelReview.new(veteran_file_number: veteran_file_number) }
    let!(:higher_level_review_event_record) do
      EventRecord.create!(event_id: event2.id, backfill_record: higher_level_review)
    end
    # SLC
    let!(:supplemental_claim) { SupplementalClaim.new(veteran_file_number: veteran_file_number) }
    let!(:supplemental_claim_event_record) do
      EventRecord.create!(event_id: event2.id, backfill_record: supplemental_claim)
    end
    # End Product Establishment
    let!(:end_product_establishment) do
      EndProductEstablishment.new(
        payee_code: "00",
        source: higher_level_review,
        veteran_file_number: veteran_file_number
      )
    end
    let!(:end_product_establishment_event_record) do
      EventRecord.create!(event_id: event2.id, backfill_record: end_product_establishment)
    end
    # Claimant
    let!(:appeal) { create(:appeal, receipt_date: 1.year.ago) }
    let!(:claimant) { create(:claimant, decision_review: appeal) }
    let!(:claimant_event_record) { EventRecord.create!(event_id: event2.id, backfill_record: claimant) }
    # Veteran
    let!(:veteran) { Veteran.new(file_number: veteran_file_number) }
    let!(:veteran_event_record) { EventRecord.create!(event_id: event2.id, backfill_record: veteran) }
    # Person
    let!(:person) { create(:person, participant_id: "1129318238") }
    let!(:person_event_record) { EventRecord.create!(event_id: event2.id, backfill_record: person) }
    # Request Issue
    let!(:request_issue) { RequestIssue.new(benefit_type: "compensation") }
    let!(:request_issue_event_record) { EventRecord.create!(event_id: event2.id, backfill_record: request_issue) }
    # Legacy Issue
    let!(:legacy_issue) { LegacyIssue.new(request_issue_id: 1, vacols_id: "vacols111", vacols_sequence_id: 1) }
    let!(:legacy_issue_event_record) { EventRecord.create!(event_id: event2.id, backfill_record: legacy_issue) }
    # Legacy Issue Optin
    let!(:legacy_issue_optin) { LegacyIssueOptin.new(request_issue_id: request_issue.id) }
    let!(:legacy_issue_optin_event_record) do
      EventRecord.create!(event_id: event2.id,
                          backfill_record: legacy_issue_optin)
    end
    # User
    let(:session) { { "user" => { "id" => "BrockPurdy", "station_id" => "310", "name" => "Brock Purdy" } } }
    let(:user) { User.from_session(session) }
    let!(:user_event_record) { EventRecord.create!(event_id: event2.id, backfill_record: user) }
    it "10 Event Records Backfilled ID and Type correctly match" do
      expect(higher_level_review_event_record.backfill_record_type).to eq("HigherLevelReview")
      expect(higher_level_review_event_record.backfill_record_id).to eq(higher_level_review.id)
      expect(higher_level_review.event_records.count).to eq 1
      expect(supplemental_claim_event_record.backfill_record_type).to eq("SupplementalClaim")
      expect(supplemental_claim_event_record.backfill_record_id).to eq(supplemental_claim.id)
      expect(supplemental_claim.event_records.count).to eq 1
      expect(end_product_establishment_event_record.backfill_record_type).to eq("EndProductEstablishment")
      expect(end_product_establishment_event_record.backfill_record_id).to eq(end_product_establishment.id)
      expect(end_product_establishment.event_records.count).to eq 1
      expect(claimant_event_record.backfill_record_type).to eq("Claimant")
      expect(claimant_event_record.backfill_record_id).to eq(claimant.id)
      expect(claimant.event_records.count).to eq 1
      expect(veteran_event_record.backfill_record_type).to eq("Veteran")
      expect(veteran_event_record.backfill_record_id).to eq(veteran.id)
      expect(veteran.event_records.count).to eq 1
      expect(person_event_record.backfill_record_type).to eq("Person")
      expect(person_event_record.backfill_record_id).to eq(person.id)
      expect(person.event_records.count).to eq 1
      expect(request_issue_event_record.backfill_record_type).to eq("RequestIssue")
      expect(request_issue_event_record.backfill_record_id).to eq(request_issue.id)
      expect(request_issue.event_records.count).to eq 1
      expect(legacy_issue_event_record.backfill_record_type).to eq("LegacyIssue")
      expect(legacy_issue_event_record.backfill_record_id).to eq(legacy_issue.id)
      expect(legacy_issue.event_records.count).to eq 1
      expect(legacy_issue_optin_event_record.backfill_record_type).to eq("LegacyIssueOptin")
      expect(legacy_issue_optin_event_record.backfill_record_id).to eq(legacy_issue_optin.id)
      expect(legacy_issue_optin.event_records.count).to eq 1
      expect(user_event_record.backfill_record_type).to eq("User")
      expect(user_event_record.backfill_record_id).to eq(user.id)
      expect(user.event_records.count).to eq 1
      expect(EventRecord.count).to eq 10
    end
  end
  # create an failing Event Record Backfill
  context "Event Record Backfill does not occur due to incorrect association" do
    let!(:attorney) { create(:bgs_attorney, name: "Brock Purdy") }
    let!(:event3) { DecisionReviewCreatedEvent.create!(reference_id: "3") }
    let!(:attorney_event_record) { EventRecord.create!(event_id: 3, backfill_record: attorney) }
    it "Event Record Backfill raises error" do
      expect { attorney.event_records }.to raise_error(NoMethodError)
    end
  end
end
