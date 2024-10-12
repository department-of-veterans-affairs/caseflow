# frozen_string_literal: true

RSpec.describe RequestIssuesUpdateEvent, type: :model do
  let(:event) { DecisionReviewUpdatedEvent.new(reference_id: "1234567890") }
  let(:user) { create(:user) }
  let(:review) { create(:higher_level_review) }
  let!(:existing_request_issue) do
    create(
      :request_issue_with_epe,
      decision_review: review,
      reference_id: "some_reference_id",
      contention_reference_id: "some_contention_id"
    )
  end
  let(:epe) { create(:end_product_establishment, source_type: "HigherLevelReview", source_id: review.id) }
  let(:last_synced_at) { Time.zone.local(2023, 7, 1, 12, 0, 0) }
  let(:parser) do
    instance_double(Events::DecisionReviewUpdated::DecisionReviewUpdatedParser).tap do |parser|
      allow(parser).to receive(:updated_issues).and_return([])
      allow(parser).to receive(:withdrawn_issues).and_return([])
      allow(parser).to receive(:added_issues).and_return([])
      allow(parser).to receive(:removed_issues).and_return([])
      allow(parser).to receive(:eligible_to_ineligible_issues).and_return([])
      allow(parser).to receive(:ineligible_to_eligible_issues).and_return([])
      allow(parser).to receive(:ineligible_to_ineligible_issues).and_return([])
      allow(parser).to receive(:end_product_establishment_last_synced_at).and_return(last_synced_at)
      allow(parser).to receive(:end_product_establishment_code).and_return("some_end_product_code")
      allow(parser).to receive(:veteran_participant_id).and_return("some_participant_id")
    end
  end

  let(:parser_issue) do
    instance_double(Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser).tap do |issue|
      allow(issue).to receive(:ri_reference_id).and_return("some_reference_id")
      allow(issue).to receive(:ri_original_caseflow_request_issue_id).and_return(nil)
      allow(issue).to receive(:ri_benefit_type).and_return("some_benefit_type")
      allow(issue).to receive(:ri_closed_at).and_return(last_synced_at)
      allow(issue).to receive(:ri_closed_status).and_return("some_status")
      allow(issue).to receive(:ri_contested_issue_description).and_return("some_description")
      allow(issue).to receive(:ri_contention_reference_id).and_return("some_contention_id")
      allow(issue).to receive(:ri_contested_rating_issue_diagnostic_code).and_return("some_diagnostic_code")
      allow(issue).to receive(:ri_contested_rating_decision_reference_id).and_return("some_decision_id")
      allow(issue).to receive(:ri_contested_rating_issue_profile_date).and_return(Time.zone.today)
      allow(issue).to receive(:ri_contested_rating_issue_reference_id).and_return("some_issue_id")
      allow(issue).to receive(:ri_contested_decision_issue_id).and_return(nil)
      allow(issue).to receive(:ri_decision_date).and_return(Time.zone.today)
      allow(issue).to receive(:ri_ineligible_due_to_id).and_return("some_ineligible_id")
      allow(issue).to receive(:ri_ineligible_reason).and_return("some_reason")
      allow(issue).to receive(:ri_is_unidentified).and_return(false)
      allow(issue).to receive(:ri_unidentified_issue_text).and_return("some_text")
      allow(issue).to receive(:ri_nonrating_issue_category).and_return("some_category")
      allow(issue).to receive(:ri_nonrating_issue_description).and_return("some_description")
      allow(issue).to receive(:ri_nonrating_issue_bgs_id).and_return("some_bgs_id")
      allow(issue).to receive(:ri_nonrating_issue_bgs_source).and_return("some_source")
      allow(issue).to receive(:ri_ramp_claim_id).and_return("some_claim_id")
      allow(issue).to receive(:ri_rating_issue_associated_at).and_return(last_synced_at)
      allow(issue).to receive(:ri_untimely_exemption).and_return(false)
      allow(issue).to receive(:ri_untimely_exemption_notes).and_return("some_notes")
      allow(issue).to receive(:ri_vacols_id).and_return("some_vacols_id")
      allow(issue).to receive(:ri_vacols_sequence_id).and_return("some_sequence_id")
      allow(issue).to receive(:ri_type).and_return("some_type")
      allow(issue).to receive(:ri_edited_description).and_return("Edited description")
    end
  end

  let(:issue_payload) do
    {
      decision_review_issue_id: "some_reference_id",
      benefit_type: "compensation",
      closed_at: 1_625_151_600,
      closed_status: "withdrawn",
      contention_reference_id: 7_905_752,
      contested_decision_issue_id: nil,
      contested_issue_description: "Service connection for PTSD",
      contested_rating_decision_reference_id: nil,
      contested_rating_issue_diagnostic_code: "9411",
      contested_rating_issue_profile_date: 1_625_076_000,
      contested_rating_issue_reference_id: "REF9411",
      type: "RequestIssue",
      decision: [
        {
          award_event_id: 679,
          category: "decision",
          contention_id: 35,
          decision_finalized_time: nil,
          decision_recorded_time: nil,
          decision_source: "the source",
          decision_text: "",
          description: nil,
          disposition: nil,
          dta_error_explanation: nil,
          id: 1738,
          rating_profile_date: nil
        }
      ],
      decision_date: 19_568,
      ineligible_due_to_id: nil,
      ineligible_reason: nil,
      is_unidentified: false,
      nonrating_issue_bgs_id: "13",
      nonrating_issue_bgs_source: "CORP_AWARD_ATTORNEY_FEE",
      nonrating_issue_category: "Accrued Benefits",
      nonrating_issue_description: "Chapter 35 benefits",
      ramp_claim_id: "RAMP123",
      rating_issue_associated_at: 1_625_076_000,
      unidentified_issue_text: nil,
      untimely_exemption: nil,
      untimely_exemption_notes: nil,
      vacols_id: "VAC123",
      vacols_sequence_id: nil,
      edited_description: "Edited description"
    }
  end

  describe "#find_request_issue" do
    it "returns the request issue id based on reference_id" do
      result = described_class.new(
        review: review, user: user, parser: parser, event: event, epe: epe
      ).find_request_issue(parser_issue)
      expect(result).to eq(existing_request_issue)
    end

    it "returns the request issue id based on original_caseflow_request_issue_id and updates the reference_id" do
      existing_request_issue.update(reference_id: nil)
      allow(parser_issue).to receive(:ri_original_caseflow_request_issue_id).and_return(existing_request_issue.id)
      result = described_class.new(
        review: review, user: user, parser: parser, event: event, epe: epe
      ).find_request_issue(parser_issue)
      expect(result).to eq(existing_request_issue)
      expect(result.reference_id).to eq(parser_issue.ri_reference_id)
    end

    it "returns the request issue id based on contention_reference_id and updates the reference_id" do
      existing_request_issue.update(reference_id: nil)
      allow(parser_issue).to receive(:ri_original_caseflow_request_issue_id).and_return(nil)
      allow(parser_issue).to receive(:ri_contention_reference_id).and_return(
        existing_request_issue.contention_reference_id
      )
      result = described_class.new(
        review: review, user: user, parser: parser, event: event, epe: epe
      ).find_request_issue(parser_issue)
      expect(result).to eq(existing_request_issue)
      expect(result.reference_id).to eq(parser_issue.ri_reference_id)
    end

    it "raises an error if the request issue is not found" do
      allow(RequestIssue).to receive(:find_by).and_return(nil)
      expect do
        described_class.new(
          review: review,
          user: user,
          parser: parser,
          event: event,
          epe: epe
        ).find_request_issue(parser_issue)
      end.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError)
    end
  end

  describe "#perform!" do
    it "returns true if the base perform! is successful" do
      allow_any_instance_of(RequestIssuesUpdate).to receive(:perform!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_eligible_to_ineligible_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_ineligible_to_eligible_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_ineligible_to_ineligible_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:update_removed_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_withdrawn_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:create_request_issue_backfill).and_return(true)
      allow_any_instance_of(described_class).to receive(:before_issues).and_return([])
      allow_any_instance_of(described_class).to receive(:create_request_issue_backfill).and_return([])
      allow_any_instance_of(described_class).to receive(:process_legacy_issues!).and_return(true)

      subject = described_class.new(review: review, user: user, parser: parser, event: event, epe: epe)
      expect(subject).to receive(:process_eligible_to_ineligible_issues!)
      expect(subject).to receive(:process_ineligible_to_eligible_issues!)
      expect(subject).to receive(:process_ineligible_to_ineligible_issues!)
      expect(subject).to receive(:update_removed_issues!)
      expect(subject).to receive(:process_withdrawn_issues!)
      expect(subject).to receive(:create_request_issue_backfill)
      expect(subject).to receive(:before_issues)
      expect(subject).to receive(:process_legacy_issues!)
      expect(subject.perform!).to be_truthy
    end

    it "saves a new request issue" do
      issue_payload[:ineligible_due_to_id] = nil
      issue_payload[:contested_decision_issue_id] = nil
      issue_payload[:decision_review_issue_id] = "some_new_reference_id"
      allow(parser).to receive(:added_issues).and_return([issue_payload])
      subject = described_class.new(review: review, user: user, parser: parser, event: event, epe: epe)
      expect(subject.perform!).to be_truthy
      request_issue = RequestIssue.find_by(reference_id: "some_new_reference_id")
      expect(request_issue).to be
      expect(request_issue.contested_issue_description).to eq(issue_payload[:contested_issue_description])
      expect(request_issue.nonrating_issue_category).to eq(issue_payload[:nonrating_issue_category])
      expect(request_issue.nonrating_issue_description).to eq(issue_payload[:nonrating_issue_description])
      expect(request_issue.reference_id).to eq(issue_payload[:decision_review_issue_id])
      expect(request_issue.contention_reference_id).to eq(issue_payload[:contention_reference_id])
      expect(request_issue.contested_decision_issue_id).to eq(issue_payload[:contested_decision_issue_id])
      expect(request_issue.ineligible_due_to_id).to eq(issue_payload[:ineligible_due_to_id])
      expect(request_issue.is_unidentified).to eq(issue_payload[:is_unidentified])
      expect(request_issue.unidentified_issue_text).to eq(issue_payload[:unidentified_issue_text])
      expect(request_issue.vacols_id).to eq(issue_payload[:vacols_id])
      expect(request_issue.vacols_sequence_id).to eq(issue_payload[:vacols_sequence_id])
      expect(request_issue.type).to eq(issue_payload[:type])
      expect(request_issue.edited_description).to eq(nil)
      expect(request_issue.benefit_type).to eq(issue_payload[:benefit_type])
      expect(request_issue.untimely_exemption).to eq(issue_payload[:untimely_exemption])
      expect(request_issue.untimely_exemption_notes).to eq(issue_payload[:untimely_exemption_notes])
      expect(request_issue.ramp_claim_id).to eq(issue_payload[:ramp_claim_id])
      expect(request_issue.ineligible_reason).to eq(issue_payload[:ineligible_reason])
      # expect(request_issue.rating_issue_associated_at).to eq(issue_payload[:rating_issue_associated_at])
      expect(request_issue.contested_rating_issue_reference_id).to eq(
        issue_payload[:contested_rating_issue_reference_id]
      )
      expect(request_issue.contested_rating_issue_diagnostic_code).to eq(
        issue_payload[:contested_rating_issue_diagnostic_code]
      )
      expect(request_issue.contested_rating_decision_reference_id).to eq(
        issue_payload[:contested_rating_decision_reference_id]
      )
      # expect(request_issue.decision_date).to eq(issue_payload[:decision_date])
      expect(request_issue.veteran_participant_id).to eq(issue_payload[:veteran_participant_id])
    end
  end

  describe "#process_eligible_to_ineligible_issues!" do
    it "updates the request issues to ineligible" do
      issue_payload[:ineligible_reason] = "untimely"
      issue_payload[:contention_reference_id] = nil
      issue_payload[:closed_at] = 1_625_151_600
      issue_payload[:nonrating_issue_description] = "some_nonrating_issue_description"
      allow(parser).to receive(:eligible_to_ineligible_issues).and_return([issue_payload])
      expect(
        described_class.new(
          review: review,
          user: user,
          parser: parser,
          event: event,
          epe: epe
        ).process_eligible_to_ineligible_issues!
      ).to be_truthy
      request_issue = RequestIssue.find(existing_request_issue.id)
      expect(request_issue.ineligible_reason).to eq(issue_payload[:ineligible_reason])
      expect(request_issue.closed_at).to eq("1970-01-19 14:25:51.000000000 -0500")
      expect(request_issue.contention_removed_at).to be
      expect(request_issue.contested_issue_description).to eq(issue_payload[:contested_issue_description])
      expect(request_issue.nonrating_issue_category).to eq(issue_payload[:nonrating_issue_category])
      expect(request_issue.nonrating_issue_description).to eq(issue_payload[:nonrating_issue_description])
      expect(request_issue.contention_removed_at).to eq(parser.end_product_establishment_last_synced_at)
      expect(request_issue.event_records.last.info["update_type"]).to eq("E2I")
      expect(request_issue.event_records.last.info["record_data"]["id"]).to eq(request_issue.id)
      expect(request_issue.contention_reference_id).to eq(issue_payload[:contention_reference_id])
    end
  end

  describe "#process_ineligible_to_eligible_issues!" do
    it "updates the request issues to eligible" do
      existing_request_issue.update(
        ineligible_reason: "untimely",
        closed_status: "ineligible",
        closed_at: Time.zone.now,
        contention_reference_id: nil,
        contention_removed_at: nil
      )
      issue_payload[:closed_status] = nil
      allow(parser).to receive(:ineligible_to_eligible_issues).and_return([issue_payload])
      expect(
        described_class.new(
          review: review,
          user: user,
          parser: parser,
          event: event,
          epe: epe
        ).process_ineligible_to_eligible_issues!
      ).to be_truthy
      existing_request_issue.reload
      expect(existing_request_issue.ineligible_reason).to eq(nil)
      # expect(existing_request_issue.closed_status).to eq(nil)
      # expect(existing_request_issue.closed_at).to eq(nil)
      expect(existing_request_issue.contention_reference_id).to eq(issue_payload[:contention_reference_id])
      expect(existing_request_issue.contention_removed_at).to eq(nil)
      expect(existing_request_issue.contested_issue_description).to eq(issue_payload[:contested_issue_description])
      expect(existing_request_issue.nonrating_issue_category).to eq(issue_payload[:nonrating_issue_category])
      expect(existing_request_issue.nonrating_issue_description).to eq(issue_payload[:nonrating_issue_description])
      expect(existing_request_issue.event_records.last.info["update_type"]).to eq("I2E")
      expect(existing_request_issue.event_records.last.info["record_data"]["id"]).to eq(existing_request_issue.id)
      expect(existing_request_issue.contention_reference_id).to eq(issue_payload[:contention_reference_id])
    end
  end

  describe "#process_ineligible_to_ineligible_issues!" do
    it "updates the request issues to ineligible" do
      existing_request_issue.update(
        ineligible_reason: "untimely",
        closed_status: "ineligible",
        closed_at: Time.zone.now
      )
      issue_payload[:ineligible_reason] = "before_ama"
      issue_payload[:closed_at] = 1_625_151_600
      allow(parser).to receive(:ineligible_to_ineligible_issues).and_return([issue_payload])
      expect(
        described_class.new(
          review: review,
          user: user,
          parser: parser,
          event: event,
          epe: epe
        ).process_ineligible_to_ineligible_issues!
      ).to be_truthy
      existing_request_issue.reload
      expect(existing_request_issue.ineligible_reason).to eq(issue_payload[:ineligible_reason])
      expect(existing_request_issue.closed_at).to eq("1970-01-19 14:25:51.000000000 -0500")
      expect(existing_request_issue.contested_issue_description).to eq(issue_payload[:contested_issue_description])
      expect(existing_request_issue.nonrating_issue_category).to eq(issue_payload[:nonrating_issue_category])
      expect(existing_request_issue.nonrating_issue_description).to eq(issue_payload[:nonrating_issue_description])
      expect(existing_request_issue.event_records.last.info["update_type"]).to eq("I2I")
      expect(existing_request_issue.event_records.last.info["record_data"]["id"]).to eq(existing_request_issue.id)
      expect(existing_request_issue.contention_reference_id).to eq(issue_payload[:contention_reference_id])
    end
  end

  describe "#update_removed_issues!" do
    it "updates the closed_at date and closed_status for removed issues" do
      allow(parser).to receive(:removed_issues).and_return([issue_payload])
      subject = described_class.new(review: review, user: user, parser: parser, event: event, epe: epe)
      expect(subject.update_removed_issues!).to be_truthy
      existing_request_issue.reload
      expect(existing_request_issue.closed_at).to eq("1970-01-19 14:25:51.000000000 -0500")
      expect(existing_request_issue.closed_status).to eq(issue_payload[:closed_status])
      expect(existing_request_issue.contention_removed_at).to eq(parser.end_product_establishment_last_synced_at)
      expect(existing_request_issue.contention_updated_at).to eq(parser.end_product_establishment_last_synced_at)
    end
  end

  describe "#process_job" do
    it "updates the statuses to attempted, submitted, processed" do
      allow(parser).to receive(:updated_issues).and_return([issue_payload])
      subject = described_class.new(review: review, user: user, parser: parser, event: event, epe: epe)
      expect(subject.perform!).to be_truthy
      expect(subject.attempted_at).to eq(parser.end_product_establishment_last_synced_at)
      expect(subject.submitted_at).to eq(parser.end_product_establishment_last_synced_at)
      expect(subject.processed_at).to eq(parser.end_product_establishment_last_synced_at)
    end
  end
end
