# frozen_string_literal: true

describe EventRecord, :postgres do
  context "One Event with One Event Record with One Intake" do
    let(:user) { Generators::User.build }
    let(:veteran_file_number) { "64205050" }
    let!(:event1) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
    let!(:intake) { Intake.create!(veteran_file_number: veteran_file_number, user: user) }
    let!(:intake_event_record) { EventRecord.create!(event: event1, evented_record: intake) }
    it "Event Record backfill ID and type should match Intake ID and type" do
      expect(intake_event_record.evented_record_type).to eq("Intake")
      expect(intake_event_record.evented_record_id).to eq(intake.id)
      expect(intake.event_record).to eq intake_event_record
      expect(intake.from_decision_review_created_event?).to eq(true)
    end
  end

  context "One Event with 10 Different Event Records to simulate a VBMS backfill" do
    let(:user) { Generators::User.build }
    let(:veteran_file_number) { "64205050" }
    let!(:event2) { DecisionReviewCreatedEvent.create!(reference_id: "2") }
    # Intake
    let!(:intake) { Intake.create!(veteran_file_number: veteran_file_number, user: user) }
    let!(:intake_event_record) { EventRecord.create!(event: event2, evented_record: intake) }
    # HLR
    let!(:higher_level_review) { HigherLevelReview.new(veteran_file_number: veteran_file_number) }
    let!(:higher_level_review_event_record) do
      EventRecord.create!(event: event2, evented_record: higher_level_review)
    end
    # SC, not tied to Event
    let!(:supplemental_claim) { SupplementalClaim.new(veteran_file_number: veteran_file_number) }

    # End Product Establishment
    let!(:end_product_establishment) do
      EndProductEstablishment.new(
        payee_code: "00",
        source: higher_level_review,
        veteran_file_number: veteran_file_number
      )
    end
    # Claimant
    let!(:appeal) { create(:appeal, receipt_date: 1.year.ago) }
    let!(:claimant) { create(:claimant, decision_review: appeal) }
    let!(:claimant_event_record) { EventRecord.create!(event: event2, evented_record: claimant) }
    # Veteran
    let!(:veteran) { Veteran.new(file_number: veteran_file_number) }
    let!(:veteran_event_record) { EventRecord.create!(event: event2, evented_record: veteran) }
    # Person
    let!(:person) { create(:person, participant_id: "1129318238") }
    let!(:person_event_record) { EventRecord.create!(event: event2, evented_record: person) }
    # Request Issue
    let!(:request_issue) { RequestIssue.new(benefit_type: "compensation", decision_review: higher_level_review) }
    let!(:request_issue_event_record) { EventRecord.create!(event: event2, evented_record: request_issue) }
    # Legacy Issue
    let!(:legacy_issue) do
      LegacyIssue.new(request_issue_id: request_issue.id, vacols_id: "vacols111", vacols_sequence_id: 1)
    end
    let!(:legacy_issue_event_record) { EventRecord.create!(event: event2, evented_record: legacy_issue) }
    # Legacy Issue Optin
    let!(:legacy_issue_optin) { LegacyIssueOptin.new(request_issue_id: request_issue.id) }
    let!(:legacy_issue_optin_event_record) do
      EventRecord.create!(event: event2, evented_record: legacy_issue_optin)
    end
    # User
    let(:session) { { "user" => { "id" => "BrockPurdy", "station_id" => "310", "name" => "Brock Purdy" } } }
    let(:user) { User.from_session(session) }
    let!(:user_event_record) { EventRecord.create!(event: event2, evented_record: user) }
    it "9 Event Records Backfilled ID and Type correctly match" do
      intake.update!(detail: higher_level_review)
      expect(higher_level_review.from_decision_review_created_event?).to eq(true)

      expect(claimant_event_record.evented_record_type).to eq("Claimant")
      expect(claimant_event_record.evented_record_id).to eq(claimant.id)
      expect(claimant.event_record).to eq claimant_event_record
      expect(end_product_establishment.from_decision_review_created_event?).to eq(true)

      expect(veteran_event_record.evented_record_type).to eq("Veteran")
      expect(veteran_event_record.evented_record_id).to eq(veteran.id)
      expect(veteran.event_record).to eq veteran_event_record
      expect(veteran.from_decision_review_created_event?).to eq(true)

      expect(person_event_record.evented_record_type).to eq("Person")
      expect(person_event_record.evented_record_id).to eq(person.id)
      expect(person.event_record).to eq person_event_record
      expect(person.from_decision_review_created_event?).to eq(true)

      expect(request_issue_event_record.evented_record_type).to eq("RequestIssue")
      expect(request_issue_event_record.evented_record_id).to eq(request_issue.id)
      expect(request_issue.event_record).to eq request_issue_event_record
      expect(request_issue.from_decision_review_created_event?).to eq(true)

      expect(legacy_issue_event_record.evented_record_type).to eq("LegacyIssue")
      expect(legacy_issue_event_record.evented_record_id).to eq(legacy_issue.id)
      expect(legacy_issue.event_record).to eq legacy_issue_event_record
      expect(legacy_issue.from_decision_review_created_event?).to eq(true)

      expect(legacy_issue_optin_event_record.evented_record_type).to eq("LegacyIssueOptin")
      expect(legacy_issue_optin_event_record.evented_record_id).to eq(legacy_issue_optin.id)
      expect(legacy_issue_optin.event_record).to eq legacy_issue_optin_event_record
      expect(legacy_issue_optin.from_decision_review_created_event?).to eq(true)

      expect(user_event_record.evented_record_type).to eq("User")
      expect(user_event_record.evented_record_id).to eq(user.id)
      expect(user.event_record).to eq user_event_record
      expect(user.from_decision_review_created_event?).to eq(true)

      expect(EventRecord.count).to eq 9
    end

    it "SupplementalClaim not associated to a backfill Intake should fail #from_decision_review_created_event?" do
      expect(supplemental_claim.from_decision_review_created_event?).to eq(false)
    end
  end

  # create an failing Event Record association
  context "EventRecord does not have a bi-directional association with non related models" do
    let!(:attorney) { create(:bgs_attorney, name: "Brock Purdy") }
    let!(:event3) { DecisionReviewCreatedEvent.create!(reference_id: "3") }
    it "should not create an EventRecord and should raise an error" do
      expect { EventRecord.create!(event_id: event3.id, evented_record: attorney) }
        .to raise_error(ActiveRecord::RecordInvalid)
      expect { attorney.event_record }.to raise_error(NoMethodError)
    end
  end
end
