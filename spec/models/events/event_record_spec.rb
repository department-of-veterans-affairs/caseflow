# frozen_string_literal: true

describe EventRecord, :postgres do
  describe "One Event with One Event Record with One Intake" do
    let(:user) { Generators::User.build }
    let(:veteran_file_number) { "64205050" }
    let!(:event1) { DecisionReviewCreatedEvent.create!(reference_id: "1") }
    let!(:intake1) { Intake.create!(veteran_file_number: veteran_file_number, user: user) }
    let!(:event_record) { EventRecord.create!(event_id: event1.id, backfill_record: intake1) }
    it "Event Record backfill ID and type match Intake ID and type" do
      expect(event_record.backfill_record_id).to eq(intake1.id)
      expect(event_record.backfill_record_type).to be_truthy
      expect(event_record.backfill_record_type).to eq("Intake")
    end
  end
  describe "One Event with 10 Different Event Records" do
    let(:veteran_file_number) { "64205050" }
    let!(:event2) { DecisionReviewCreatedEvent.create!(reference_id: "2") }
    # HLR
    let!(:hlr1) { HigherLevelReview.create!(veteran_file_number: veteran_file_number) }
    let!(:event_record1) { EventRecord.create!(event_id: event2.id, backfill_record: hlr1) }
    # SLC
    let!(:slc1) { SupplementalClaim.new(veteran_file_number: veteran_file_number) }
    let!(:event_record2) { EventRecord.create!(event_id: event2.id, backfill_record: slc1) }
    # End Product Establishment
    let!(:epe1) do
      EndProductEstablishment.new(
        payee_code: "00",
        source: hlr1,
        veteran_file_number: veteran_file_number
      )
    end
    let!(:event_record3) { EventRecord.create!(event_id: event2.id, backfill_record: epe1) }
    # Claimant
    let!(:appeal) { create(:appeal, receipt_date: 1.year.ago) }
    let!(:claimant) { create(:claimant, decision_review: appeal) }
    let!(:event_record4) { EventRecord.create!(event_id: event2.id, backfill_record: claimant) }
    # Veteran
    let!(:vet1) { Veteran.new(file_number: veteran_file_number) }
    let!(:event_record5) { EventRecord.create!(event_id: event2.id, backfill_record: vet1) }
    # Person
    let!(:person) { create(:person, participant_id: "1129318238") }
    let!(:event_record6) { EventRecord.create!(event_id: event2.id, backfill_record: person) }
    # Request Issue
    let!(:ri1) { RequestIssue.new(benefit_type: "compensation") }
    let!(:event_record7) { EventRecord.create!(event_id: event2.id, backfill_record: ri1) }
    # Legacy Issue
    let!(:legacy_issue1) { LegacyIssue.new(request_issue_id: 1, vacols_id: "vacols111", vacols_sequence_id: 1) }
    let!(:event_record8) { EventRecord.create!(event_id: event2.id, backfill_record: legacy_issue1) }
    # Legacy Issue Optin
    let!(:legacy_issue_optin1) { LegacyIssueOptin.new(request_issue_id: ri1.id) }
    let!(:event_record9) { EventRecord.create!(event_id: event2.id, backfill_record: legacy_issue_optin1) }
    # User
    let(:session) { { "user" => { "id" => "BrockPurdy", "station_id" => "310", "name" => "Brock Purdy" } } }
    let(:user) { User.from_session(session) }
    let!(:event_record10) { EventRecord.create!(event_id: event2.id, backfill_record: user) }
    it "10 Event Records Backfilled ID and Type correctly match" do
      expect(event_record1.backfill_record_id).to eq(hlr1.id)
      expect(event_record1.backfill_record_type).to be_truthy
      expect(event_record1.backfill_record_type).to eq("HigherLevelReview")
      expect(event_record2.backfill_record_id).to eq(slc1.id)
      expect(event_record2.backfill_record_type).to be_truthy
      expect(event_record2.backfill_record_type).to eq("SupplementalClaim")
      expect(event_record3.backfill_record_id).to eq(epe1.id)
      expect(event_record3.backfill_record_type).to be_truthy
      expect(event_record3.backfill_record_type).to eq("EndProductEstablishment")
      expect(event_record4.backfill_record_id).to eq(claimant.id)
      expect(event_record4.backfill_record_type).to be_truthy
      expect(event_record4.backfill_record_type).to eq("Claimant")
      expect(event_record5.backfill_record_id).to eq(vet1.id)
      expect(event_record5.backfill_record_type).to be_truthy
      expect(event_record5.backfill_record_type).to eq("Veteran")
      expect(event_record6.backfill_record_id).to eq(person.id)
      expect(event_record6.backfill_record_type).to be_truthy
      expect(event_record6.backfill_record_type).to eq("Person")
      expect(event_record7.backfill_record_id).to eq(ri1.id)
      expect(event_record7.backfill_record_type).to be_truthy
      expect(event_record7.backfill_record_type).to eq("RequestIssue")
      expect(event_record8.backfill_record_id).to eq(legacy_issue1.id)
      expect(event_record8.backfill_record_type).to be_truthy
      expect(event_record8.backfill_record_type).to eq("LegacyIssue")
      expect(event_record9.backfill_record_id).to eq(legacy_issue_optin1.id)
      expect(event_record9.backfill_record_type).to be_truthy
      expect(event_record9.backfill_record_type).to eq("LegacyIssueOptin")
      expect(event_record10.backfill_record_id).to eq(user.id)
      expect(event_record10.backfill_record_type).to be_truthy
      expect(event_record10.backfill_record_type).to eq("User")
      expect(EventRecord.count).to eq 10
    end
  end
  # create an failing Event Record Backfill
  describe "Event Record Backfill does not occur due to incorrect association" do
    let!(:attorneys) { create(:bgs_attorney, name: "Brock Purdy") }
    let!(:event3) { DecisionReviewCreatedEvent.create!(reference_id: "3") }
    let!(:event_record) { EventRecord.create!(event_id: 3, backfill_record: attorneys) }
    it "Event Record doesnot Backfill record" do
      expect(event_record.backfill_record_type).to be_falsey
    end
  end
end
