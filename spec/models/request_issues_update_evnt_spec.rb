# frozen_string_literal: true

RSpec.describe RequestIssuesUpdateEvnt, type: :model do
  let(:user) { create(:user) }
  let(:review) { create(:higher_level_review) }
  let!(:existing_request_issue) { create(:request_issue, decision_review: review, reference_id: "some_reference_id") }
  let(:parser) do
    instance_double(Events::DecisionReviewUpdated::DecisionReviewUpdatedParser).tap do |parser|
      allow(parser).to receive(:updated_issues).and_return([])
      allow(parser).to receive(:withdrawn_issues).and_return([])
      allow(parser).to receive(:added_issues).and_return([])
      allow(parser).to receive(:removed_issues).and_return([])
    end
  end

  let(:parser_issue) do
    instance_double(Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser).tap do |issue|
      allow(issue).to receive(:ri_reference_id).and_return("some_reference_id")
      allow(issue).to receive(:ri_benefit_type).and_return("some_benefit_type")
      allow(issue).to receive(:ri_closed_at).and_return(Time.zone.now)
      allow(issue).to receive(:ri_closed_status).and_return("some_status")
      allow(issue).to receive(:ri_contested_issue_description).and_return("some_description")
      allow(issue).to receive(:ri_contention_reference_id).and_return("some_contention_id")
      allow(issue).to receive(:ri_contested_rating_issue_diagnostic_code).and_return("some_diagnostic_code")
      allow(issue).to receive(:ri_contested_rating_decision_reference_id).and_return("some_decision_id")
      allow(issue).to receive(:ri_contested_rating_issue_profile_date).and_return(Time.zone.today)
      allow(issue).to receive(:ri_contested_rating_issue_reference_id).and_return("some_issue_id")
      allow(issue).to receive(:ri_contested_decision_issue_id).and_return("some_decision_issue_id")
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
      allow(issue).to receive(:ri_rating_issue_associated_at).and_return(Time.zone.now)
      allow(issue).to receive(:ri_untimely_exemption).and_return(false)
      allow(issue).to receive(:ri_untimely_exemption_notes).and_return("some_notes")
      allow(issue).to receive(:ri_vacols_id).and_return("some_vacols_id")
      allow(issue).to receive(:ri_vacols_sequence_id).and_return("some_sequence_id")
      allow(issue).to receive(:ri_veteran_participant_id).and_return("some_participant_id")
      allow(issue).to receive(:ri_type).and_return("some_type")
      allow(issue).to receive(:ri_decision).and_return("some_decision")
    end
  end

  let(:issue_payload) do
    {
      decision_review_issue_id: "some_reference_id",
      benefit_type: "compensation",
      closed_at: 1_625_151_600,
      closed_status: "withdrawn",
      contention_reference_id: 7_905_752,
      contested_decision_issue_id: 201,
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
      ineligible_due_to_id: 301,
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
      vacols_sequence_id: nil
    }
  end

  describe "#initialize" do
    it "calls build_request_issues_data" do
      expect_any_instance_of(RequestIssuesUpdateEvnt).to receive(:build_request_issues_data)
      described_class.new(review: review, user: user, parser: parser)
    end
  end

  describe "#find_request_issue_id" do
    it "returns the request issue id" do
      result = described_class.new(review: review, user: user, parser: parser).find_request_issue_id(parser_issue)
      expect(result).to eq(existing_request_issue.id)
    end

    it "raises an error if the request issue is not found" do
      allow(RequestIssue).to receive(:find_by).and_return(nil)
      expect do
        described_class.new(review: review, user: user, parser: parser).find_request_issue_id(parser_issue)
      end.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError)
    end
  end

  describe "#build_issue_data" do
    it "returns an empty hash if the parser issue is nil" do
      result = described_class.new(review: review, user: user, parser: parser).build_issue_data(parser_issue: nil)
      expect(result).to eq({})
    end

    it "returns a hash of request issue data" do
      result = described_class.new(review: review, user: user, parser: parser).build_issue_data(
        parser_issue: parser_issue
      )
      expect(result).to eq(
        {
          request_issue_id: existing_request_issue.id,
          benefit_type: parser_issue.ri_benefit_type,
          closed_date: parser_issue.ri_closed_at,
          withdrawal_date: nil,
          closed_status: parser_issue.ri_closed_status,
          contention_reference_id: parser_issue.ri_contention_reference_id,
          contested_decision_issue_id: parser_issue.ri_contested_decision_issue_id,
          contested_rating_issue_reference_id: parser_issue.ri_contested_rating_issue_reference_id,
          contested_rating_issue_diagnostic_code: parser_issue.ri_contested_rating_issue_diagnostic_code,
          contested_rating_decision_reference_id: parser_issue.ri_contested_rating_decision_reference_id,
          contested_rating_issue_profile_date: parser_issue.ri_contested_rating_issue_profile_date,
          contested_issue_description: parser_issue.ri_contested_issue_description,
          unidentified_issue_text: parser_issue.ri_unidentified_issue_text,
          decision_date: parser_issue.ri_decision_date,
          nonrating_issue_category: parser_issue.ri_nonrating_issue_category,
          nonrating_issue_description: parser_issue.ri_nonrating_issue_description,
          is_unidentified: parser_issue.ri_is_unidentified,
          untimely_exemption: parser_issue.ri_untimely_exemption,
          untimely_exemption_notes: parser_issue.ri_untimely_exemption_notes,
          ramp_claim_id: parser_issue.ri_ramp_claim_id,
          vacols_id: parser_issue.ri_vacols_id,
          vacols_sequence_id: parser_issue.ri_vacols_sequence_id,
          ineligible_reason: parser_issue.ri_ineligible_reason,
          ineligible_due_to_id: parser_issue.ri_ineligible_due_to_id,
          reference_id: parser_issue.ri_reference_id,
          type: parser_issue.ri_type,
          veteran_participant_id: parser_issue.ri_veteran_participant_id,
          rating_issue_associated_at: parser_issue.ri_rating_issue_associated_at,
          nonrating_issue_bgs_source: parser_issue.ri_nonrating_issue_bgs_source,
          nonrating_issue_bgs_id: parser_issue.ri_nonrating_issue_bgs_id
        }
      )
    end

    it "returns a hash of request issue data with a withdrawal date equal to the closed date" do
      result = described_class.new(
        review: review, user: user, parser: parser
      ).build_issue_data(parser_issue: parser_issue, is_withdrawn: true)
      expect(result[:withdrawal_date]).to eq(result[:closed_date])
    end
  end

  describe "#build_request_issues_data" do
    it "returns an array of request issue data for updated issues" do
      allow(parser).to receive(:updated_issues).and_return([issue_payload])
      allow(Events::DecisionReviewUpdated::DecisionReviewUpdatedIssueParser).to receive(:new).and_return(parser_issue)
      issue_data = described_class.new(review: review, user: user, parser: parser).build_issue_data(
        parser_issue: parser_issue
      )
      result = described_class.new(review: review, user: user, parser: parser).build_request_issues_data
      expect(result).to eq([issue_data])
    end
  end

  describe "#perform!" do
    it "returns true if the base perform! is successful" do
      allow_any_instance_of(RequestIssuesUpdate).to receive(:perform!).and_return(true)
      allow_any_instance_of(described_class).to receive(:remove_request_issues_with_no_decision!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_eligible_to_ineligible_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_ineligible_to_eligible_issues!).and_return(true)
      allow_any_instance_of(described_class).to receive(:process_ineligible_to_ineligible_issues!).and_return(true)
      subject = described_class.new(review: review, user: user, parser: parser)
      expect(subject).to receive(:remove_request_issues_with_no_decision!)
      expect(subject).to receive(:process_eligible_to_ineligible_issues!)
      expect(subject).to receive(:process_ineligible_to_eligible_issues!)
      expect(subject).to receive(:process_ineligible_to_ineligible_issues!)
      expect(subject.perform!).to be_truthy
    end
  end

  describe "#remove_request_issues_with_no_decision!" do
    it "removes request issues with no decision" do
      allow_any_instance_of(RequestIssueClosure).to receive(:with_no_decision!).and_return(true)
      allow(parser).to receive(:removed_issues).and_return([issue_payload])
      allow_any_instance_of(described_class).to receive(:check_for_mismatched_closed_issues!).and_return(true)
      expect(described_class.new(review: review, user: user, parser: parser).remove_request_issues_with_no_decision!).to be_truthy
    end
  end

  describe "#check_for_mismatched_closed_issues!" do
    it "raises an error if the issues are mismatched" do
      issue_payload[:decision_review_issue_id] = "some_diff_reference_id"
      allow(parser).to receive(:removed_issues).and_return([issue_payload])
      allow_any_instance_of(RequestIssuesUpdate).to receive(:removed_issues).and_return([existing_request_issue])
      expect do
        described_class.new(review: review, user: user, parser: parser).check_for_mismatched_closed_issues!
      end.to raise_error(Caseflow::Error::DecisionReviewUpdateMismatchedRemovedIssuesError)
    end

    it "does not raise an error if the removed issues are matched" do
      allow(parser).to receive(:removed_issues).and_return([issue_payload])
      allow_any_instance_of(RequestIssuesUpdate).to receive(:removed_issues).and_return([existing_request_issue])
      expect do
        described_class.new(review: review, user: user, parser: parser).check_for_mismatched_closed_issues!
      end.to_not raise_error
    end

    it "raises an error if the removed issues are missing in Caseflow" do
      allow(parser).to receive(:removed_issues).and_return([issue_payload])
      allow_any_instance_of(RequestIssuesUpdate).to receive(:removed_issues).and_return([])
      expect do
        described_class.new(review: review, user: user, parser: parser).check_for_mismatched_closed_issues!
      end.to raise_error(Caseflow::Error::DecisionReviewUpdateMismatchedRemovedIssuesError)
    end

    it "raises an error if the removed issues are missing in parser" do
      allow(parser).to receive(:removed_issues).and_return([])
      allow_any_instance_of(RequestIssuesUpdate).to receive(:removed_issues).and_return([existing_request_issue])
      expect do
        described_class.new(review: review, user: user, parser: parser).check_for_mismatched_closed_issues!
      end.to raise_error(Caseflow::Error::DecisionReviewUpdateMismatchedRemovedIssuesError)
    end
  end

  describe "#process_eligible_to_ineligible_issues!" do
    it "updates the request issues to ineligible" do
      issue_payload[:ineligible_reason] = "untimely"
      issue_payload[:contention_reference_id] = nil
      issue_payload[:closed_at] = 1_625_151_600
      allow(parser).to receive(:eligible_to_ineligible_issues).and_return([issue_payload])
      expect(described_class.new(review: review, user: user, parser: parser).process_eligible_to_ineligible_issues!).to be_truthy
      request_issue = RequestIssue.find(existing_request_issue.id)
      expect(request_issue.ineligible_reason).to eq(issue_payload[:ineligible_reason])
      expect(request_issue.closed_at).to eq("1970-01-19 14:25:51.000000000 -0500")
      expect(request_issue.contention_removed_at).to be
    end
  end

  describe "#process_ineligible_to_eligible_issues!" do
    it "updates the request issues to eligible" do
      existing_request_issue.update(
        ineligible_reason: "untimely",
        closed_status: "ineligible",
        closed_at: Time.zone.now
      )
      allow(parser).to receive(:ineligible_to_eligible_issues).and_return([issue_payload])
      expect(described_class.new(review: review, user: user, parser: parser).process_ineligible_to_eligible_issues!).to be_truthy
      existing_request_issue.reload
      expect(existing_request_issue.ineligible_reason).to eq(nil)
      expect(existing_request_issue.closed_status).to eq(nil)
      expect(existing_request_issue.closed_at).to eq(nil)
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
      expect(described_class.new(review: review, user: user, parser: parser).process_ineligible_to_ineligible_issues!).to be_truthy
      existing_request_issue.reload
      expect(existing_request_issue.ineligible_reason).to eq(issue_payload[:ineligible_reason])
      expect(existing_request_issue.closed_at).to eq("1970-01-19 14:25:51.000000000 -0500")
    end
  end
end
