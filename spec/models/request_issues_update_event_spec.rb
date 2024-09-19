# frozen_string_literal: true

RSpec.describe RequestIssuesUpdateEvent, type: :model do
  let(:user) { create(:user) }
  let(:review) { create(:supplemental_claim) }

  let(:parser) do
    json_path = Rails.root.join("app",
                                "services", "events", "decision_review_updated",
                                "decision_review_updated_example.json")
    json_content = File.read(json_path)
    Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new(nil, JSON.parse(json_content))
  end

  subject do
    described_class.new(
      user: user,
      review: review,
      parser: parser
    )
  end

  describe "#perform!" do
    context "when valid and not processed" do
      before do
        allow(subject).to receive(:validate_before_perform).and_return(true)
        allow(subject).to receive(:processed?).and_return(false)
        allow(subject).to receive(:transaction).and_yield
        allow(subject).to receive(:process_job).and_return(true)
      end

      it "processes issues and returns true" do
        expect(subject).to receive(:process_issues!)
        expect(subject.perform!).to be true
      end

      it "updates the review and issues" do
        allow(subject).to receive(:process_issues!)
        expect(subject).to receive(:update!).with(
          before_request_issue_ids: anything,
          after_request_issue_ids: anything,
          withdrawn_request_issue_ids: anything,
          edited_request_issue_ids: anything
        )
        subject.perform!
      end
    end

    context "when validation fails" do
      it "returns false" do
        allow(subject).to receive(:validate_before_perform).and_return(false)
        expect(subject.perform!).to be false
      end
    end
  end

  describe "#after_issues" do
    it "calculates or fetches the after issues" do
      allow(subject).to receive(:after_request_issue_ids).and_return(nil)
      expect(subject).to receive(:calculate_after_issues).and_return([])
      subject.after_issues
    end
  end

  describe "#edited_issues" do
    it "calculates or fetches the edited issues" do
      allow(subject).to receive(:edited_request_issue_ids).and_return(nil)
      expect(subject).to receive(:calculate_edited_issues).and_return([])
      subject.edited_issues
    end
  end

  describe "#added_issues" do
    it "calculates the added issues" do
      expect(subject).to receive(:calculate_added_issues).and_return(parser.added_issues)
      subject.added_issues
    end
  end

  describe "#removed_issues" do
    it "calculates the removed issues" do
      expect(subject).to receive(:removed_issues).and_return(parser.removed_issues)
      subject.removed_issues
    end
  end

  describe "#withdrawn_issues" do
    it "calculates or fetches the withdrawn issues" do
      allow(subject).to receive(:withdrawn_request_issue_ids).and_return(nil)
      expect(subject).to receive(:calculate_withdrawn_issues).and_return(parser.withdrawn_issues)
      subject.withdrawn_issues
    end
  end

  describe "#validate_before_perform" do
    context "when there are no changes" do
      it "sets error_code to :no_changes and returns false" do
        allow(subject).to receive(:changes?).and_return(false)
        expect(subject.send(:validate_before_perform)).to be false
        expect(subject.error_code).to eq(:no_changes)
      end
    end
  end

  describe "#perform!" do
    context "when only added issues are present" do
      before do
        subject.instance_variable_set(:@added_issue_data, parser.added_issues)
        subject.instance_variable_set(:@removed_issue_data, [])
        subject.instance_variable_set(:@edited_issue_data, [])
        subject.instance_variable_set(:@withdrawn_issue_data, [])

        allow(subject).to receive(:validate_before_perform).and_return(true)
        allow(subject).to receive(:processed?).and_return(false)
        allow(subject).to receive(:transaction).and_yield
        allow(subject).to receive(:process_job).and_return(true)
      end

      it "processes only the added issues and returns true" do
        expect(subject).to receive(:process_issues!)
        expect(subject.perform!).to be true
      end

      it "updates the review and issues with added issues only" do
        allow(subject).to receive(:process_issues!)
        expect(subject).to receive(:update!).with(
          before_request_issue_ids: anything,
          after_request_issue_ids: anything,
          withdrawn_request_issue_ids: anything,
          edited_request_issue_ids: anything
        )
        subject.perform!
      end
    end
  end

  describe "#calculate_added_issues" do
    let(:multiple_issue_data) { parser.added_issues + parser.added_issues } # Simulating multiple issues

    before do
      subject.instance_variable_set(:@added_issue_data, multiple_issue_data)
    end

    it "processes all added issues and returns the correct count" do
      added_issues = subject.send(:calculate_added_issues)
      expect(added_issues.size).to eq(2)
    end
  end

  context "when multiple types of issues are present" do
    before do
      subject.instance_variable_set(:@added_issue_data, parser.added_issues)
      subject.instance_variable_set(:@removed_issue_data, parser.removed_issues)
      subject.instance_variable_set(:@edited_issue_data, parser.updated_issues)
      subject.instance_variable_set(:@withdrawn_issue_data, parser.withdrawn_issues)

      allow(subject).to receive(:validate_before_perform).and_return(true)
      allow(subject).to receive(:processed?).and_return(false)
      allow(subject).to receive(:transaction).and_yield
    end

    it "processes all types of issues and returns true" do
      expect(subject).to receive(:process_issues!)
      expect(subject.perform!).to be true
    end
  end

  context "when an exception occurs during transaction" do
    before do
      allow(subject).to receive(:validate_before_perform).and_return(true)
      allow(subject).to receive(:processed?).and_return(false)
      allow(subject).to receive(:transaction).and_raise(StandardError)
    end

    it "raises an error and does not commit changes" do
      expect { subject.perform! }.to raise_error(StandardError)
      expect(subject).not_to receive(:process_issues!)
    end
  end

  context "when validation fails" do
    before do
      allow(subject).to receive(:validate_before_perform).and_return(false)
    end

    it "returns false and does not process issues" do
      expect(subject).not_to receive(:process_issues!)
      expect(subject.perform!).to be false
    end
  end

  context "when handling errors in #process_withdrawn_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@withdrawn_issue_data, [{ reference_id: invalid_reference_id }])
      allow(review.request_issues).to receive(:find_by)
        .with(reference_id: invalid_reference_id)
        .and_return(nil)
    end

    it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
      expect { subject.perform! }.to raise_error(
        Caseflow::Error::DecisionReviewUpdateMissingIssueError,
        "Request issue not found for REFERENCE_ID: #{invalid_reference_id}"
      )
    end
  end

  context "when handling errors in #process_removed_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@removed_issue_data, [{ reference_id: invalid_reference_id }])
      allow(review.request_issues).to receive(:find_by)
        .with(reference_id: invalid_reference_id)
        .and_return(nil)
    end

    it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
      expect { subject.perform! }.to raise_error(
        Caseflow::Error::DecisionReviewUpdateMissingIssueError,
        "Request issue not found for REFERENCE_ID: #{invalid_reference_id}"
      )
    end
  end

  context "when handling errors in #process_withdrawn_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@withdrawn_issue_data, [{ reference_id: invalid_reference_id }])
    end

    context "when a request issue is not found" do
      before do
        allow(RequestIssue).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
        expect { subject.perform! }.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError,
                                                   "Request issue not found for REFERENCE_ID: #{invalid_reference_id}")
      end
    end
  end

  context "when handling errors in #process_eligible_to_ineligible_issues!" do
    let(:invalid_reference_id) { "12345" }
    let(:eligible_to_ineligible_issue) do
      [{ reference_id: invalid_reference_id, ineligible_reason: "higher_level_review_to_higher_level_review" }]
    end

    before do
      subject.instance_variable_set(:@eligible_to_ineligible_issue_data, [{ reference_id: invalid_reference_id }])
    end

    context "when a request issue is not found" do
      before do
        allow(RequestIssue).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

        allow_any_instance_of(RequestIssue).to receive(:closed_at).and_return(nil)
        allow_any_instance_of(RequestIssue).to receive(:save!).and_return(true)
      end

      it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
        expect { subject.perform! }.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError,
                                                   "Request issue not found for REFERENCE_ID: #{invalid_reference_id}")
      end
    end
  end

  context "when handling errors in #process_ineligible_to_eligible_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@ineligible_to_eligible_issue_data, [{ reference_id: invalid_reference_id }])
      allow(review.request_issues).to receive(:find_by)
        .with(reference_id: invalid_reference_id)
        .and_return(nil)
    end

    it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
      expect { subject.perform! }.to raise_error(
        Caseflow::Error::DecisionReviewUpdateMissingIssueError,
        "Request issue not found for REFERENCE_ID: #{invalid_reference_id}"
      )
    end
  end

  context "when handling errors in #process_ineligible_to_ineligible_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@ineligible_to_ineligible_issue_data, [{ reference_id: invalid_reference_id }])
      allow(review.request_issues).to receive(:find_by)
        .with(reference_id: invalid_reference_id)
        .and_return(nil)
    end

    it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
      expect { subject.perform! }.to raise_error(
        Caseflow::Error::DecisionReviewUpdateMissingIssueError,
        "Request issue not found for REFERENCE_ID: #{invalid_reference_id}"
      )
    end
  end
end

describe "additional positive tests" do
  let(:user) { create(:user) }
  let(:review) { create(:supplemental_claim) }
  let(:parser) do
    json_path = Rails.root.join("app", "services", "events",
                                "decision_review_updated", "decision_review_updated_example.json")
    json_content = File.read(json_path)
    Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new(nil, JSON.parse(json_content))
  end

  let(:request_issues_update_event) do
    RequestIssuesUpdateEvent.new(
      user: user,
      review: review,
      parser: parser
    )
  end

  describe "#perform!" do
    context "when validation passes and issues are processed" do
      before do
        allow(request_issues_update_event).to receive(:validate_before_perform).and_return(true)
        allow(request_issues_update_event).to receive(:processed?).and_return(false)
        allow(review).to receive(:mark_rating_request_issues_to_reassociate!)
        allow(request_issues_update_event).to receive(:process_job)
      end

      it "processes issues and updates review" do
        expect(request_issues_update_event).to receive(:process_issues!)
        expect(request_issues_update_event).to receive(:update!)

        expect(request_issues_update_event.perform!).to be_truthy
      end
    end

    context "when validation fails" do
      before do
        allow(request_issues_update_event).to receive(:validate_before_perform).and_return(false)
      end

      it "does not process issues" do
        expect(request_issues_update_event.perform!).to be_falsey
        expect(request_issues_update_event).not_to receive(:process_issues!)
      end
    end

    context "when already processed" do
      before do
        allow(request_issues_update_event).to receive(:processed?).and_return(true)
      end

      it "does not process issues" do
        expect(request_issues_update_event.perform!).to be_falsey
        expect(request_issues_update_event).not_to receive(:process_issues!)
      end
    end
  end

  describe "#process_issues!" do
    it "calls individual issue processing methods" do
      expect(request_issues_update_event).to receive(:process_added_issues!)
      expect(request_issues_update_event).to receive(:process_removed_issues!)
      expect(request_issues_update_event).to receive(:process_withdrawn_issues!)
      expect(request_issues_update_event).to receive(:process_edited_issues!)
      expect(request_issues_update_event).to receive(:process_eligible_to_ineligible_issues!)
      expect(request_issues_update_event).to receive(:process_ineligible_to_eligible_issues!)
      expect(request_issues_update_event).to receive(:process_ineligible_to_ineligible_issues!)

      request_issues_update_event.process_issues!
    end
  end

  context "new tests" do
    let(:user) { create(:user) }
    let(:review) { create(:supplemental_claim) }

    let(:parser) do
      json_path = Rails.root.join("app", "services", "events", "decision_review_updated",
                                  "decision_review_updated_example.json")
      json_content = File.read(json_path)
      Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new(nil, JSON.parse(json_content))
    end

    let(:request_issues_update_event) do
      RequestIssuesUpdateEvent.new(
        user: user,
        review: review,
        parser: parser
      )
    end

    describe "#perform!" do
      context "when processing all types of issues successfully" do
        let!(:existing_issue1) { create(:request_issue, decision_review: review, reference_id: "1") }
        let!(:existing_issue2) { create(:request_issue, decision_review: review, reference_id: "2") }

        let(:added_issue_data) do
          [{
            reference_id: "3",
            ri_contested_issue_description: "Added Issue",
            ri_benefit_type: "compensation"
          }]
        end

        let(:removed_issue_data) { [{ reference_id: "1" }] }
        let(:edited_issue_data) do
          [{ reference_id: "2",
             edited_description: "Edited Issue", decision_date: Time.zone.today }]
        end
        let(:withdrawn_issue_data) { [{ reference_id: "2", closed_at: Time.zone.now }] }

        before do
          # Create the added issue in the database before running the test
          create(:request_issue, decision_review: review, reference_id: "3")

          request_issues_update_event.instance_variable_set(:@added_issue_data, added_issue_data)
          request_issues_update_event.instance_variable_set(:@removed_issue_data, removed_issue_data)
          request_issues_update_event.instance_variable_set(:@edited_issue_data, edited_issue_data)
          request_issues_update_event.instance_variable_set(:@withdrawn_issue_data, withdrawn_issue_data)

          allow(request_issues_update_event).to receive(:validate_before_perform).and_return(true)
          allow(request_issues_update_event).to receive(:processed?).and_return(false)
          allow(review).to receive(:mark_rating_request_issues_to_reassociate!)
          allow(request_issues_update_event).to receive(:process_job)
        end

        it "marks the issue as removed" do
          request_issues_update_event.perform!
          existing_issue1.reload
          expect(existing_issue1.closed_status).to eq("removed")
          expect(existing_issue1.closed_at).not_to be_nil
        end
      end
    end

    # 1. Testing #process_added_issues!
    describe "#process_added_issues!" do
      context "when there are added issues" do
        let!(:existing_issue1) { create(:request_issue, decision_review: review, reference_id: "1") }
        let!(:existing_issue2) { create(:request_issue, decision_review: review, reference_id: "2") }

        let(:added_issue_data) do
          [
            {
              reference_id: "3",
              ri_contested_issue_description: "Issue 3",
              ri_benefit_type: "compensation"
            },
            {
              reference_id: "4",
              ri_contested_issue_description: "Issue 4",
              ri_benefit_type: "compensation"
            }
          ]
        end

        before do
          # Create the added issues in the database
          create(:request_issue, decision_review: review, reference_id: "3")
          create(:request_issue, decision_review: review, reference_id: "4")

          request_issues_update_event.instance_variable_set(:@added_issue_data, added_issue_data)
        end
        # rubocop: disable Lint/AmbiguousBlockAssociation

        it "processes existing added issues without creating new ones" do
          expect { request_issues_update_event.process_added_issues! }
            .not_to change { review.request_issues.count }
          expect(review.request_issues.exists?(reference_id: "3")).to be_truthy
          expect(review.request_issues.exists?(reference_id: "4")).to be_truthy
        end
      end

      context "when there are no added issues" do
        before do
          request_issues_update_event.instance_variable_set(:@added_issue_data, [])
        end

        it "does not create any new request issues" do
          expect { request_issues_update_event.process_added_issues! }.not_to change { review.request_issues.count }
        end
      end
    end

    # 2. Testing #process_removed_issues!
    describe "#process_removed_issues!" do
      context "when there are removed issues" do
        let!(:existing_issue) { create(:request_issue, decision_review: review, reference_id: "1") }
        let(:removed_issue_data) { [{ reference_id: "1" }] }

        before do
          request_issues_update_event.instance_variable_set(:@removed_issue_data, removed_issue_data)
        end

        it "marks the issue as removed" do
          request_issues_update_event.process_removed_issues!
          existing_issue.reload
          expect(existing_issue.closed_status).to eq("removed")
          expect(existing_issue.closed_at).not_to be_nil
        end
      end

      context "when there are no removed issues" do
        before do
          request_issues_update_event.instance_variable_set(:@removed_issue_data, [])
        end

        it "does not alter any request issues" do
          expect { request_issues_update_event.process_removed_issues! }.not_to change { review.request_issues.count }
        end
      end
    end

    # 3. Testing #process_withdrawn_issues!
    describe "#process_withdrawn_issues!" do
      context "when there are withdrawn issues" do
        let!(:existing_issue) { create(:request_issue, decision_review: review, reference_id: "2") }
        let(:withdrawn_issue_data) { [{ reference_id: "2", closed_at: Time.zone.now }] }

        before do
          request_issues_update_event.instance_variable_set(:@withdrawn_issue_data, withdrawn_issue_data)
        end

        it "marks the issue as withdrawn with the correct closed_at date" do
          request_issues_update_event.send(:process_withdrawn_issues!)
          existing_issue.reload
          expect(existing_issue.closed_status).to eq("withdrawn")
          expect(existing_issue.closed_at).to be_within(1.second).of(withdrawn_issue_data.first[:closed_at])
        end
      end
    end

    # 4. Testing #process_edited_issues!
    describe "#process_edited_issues!" do
      context "when there are edited issues" do
        let!(:existing_issue) do
          create(:request_issue, decision_review: review, reference_id: "2", decision_date: 1.day.ago)
        end

        let(:edited_issue_data) do
          [{ reference_id: "2", edited_description: "Updated Issue", decision_date: Time.zone.today }]
        end

        before do
          request_issues_update_event.instance_variable_set(:@edited_issue_data, edited_issue_data)
        end

        it "updates the edited_description and decision date of the issue" do
          request_issues_update_event.send(:process_edited_issues!)
          existing_issue.reload
          expect(existing_issue.edited_description).to eq("Updated Issue")
          expect(existing_issue.decision_date).to eq(Time.zone.today)
        end
      end
    end

    # 5. Testing #process_eligible_to_ineligible_issues!
    describe "#process_eligible_to_ineligible_issues!" do
      context "when there are eligible to ineligible issues" do
        let!(:existing_issue) do
          create(:request_issue, decision_review: review, reference_id: "2", ineligible_reason: nil)
        end
        let(:issue_data) do
          [{ reference_id: "2", ineligible_reason: "duplicate_of_rating_issue_in_active_review",
             closed_at: Time.zone.now }]
        end

        before do
          request_issues_update_event.instance_variable_set(:@eligible_to_ineligible_issue_data, issue_data)
        end

        it "updates the issue to be ineligible with the correct reason and closed_at date" do
          request_issues_update_event.send(:process_eligible_to_ineligible_issues!)
          existing_issue.reload
          expect(existing_issue.ineligible_reason).to eq("duplicate_of_rating_issue_in_active_review")
          expect(existing_issue.closed_at).to be_within(1.second).of(issue_data.first[:closed_at])
          expect(existing_issue.contention_reference_id).to be_nil
        end
      end

      context "when there are 2 issues to process" do
        let!(:existing_issue1) do
          create(:request_issue, decision_review: review, reference_id: "1", ineligible_reason: nil)
        end

        let!(:existing_issue2) do
          create(:request_issue, decision_review: review, reference_id: "2", ineligible_reason: nil)
        end

        let(:issue_data) do
          [
            { reference_id: "1", ineligible_reason: "untimely", closed_at: Time.zone.now },
            { reference_id: "2", ineligible_reason: "appeal_to_appeal", closed_at: Time.zone.now }
          ]
        end

        before do
          request_issues_update_event.instance_variable_set(:@eligible_to_ineligible_issue_data, issue_data)
        end

        it "updates all eligible issues" do
          request_issues_update_event.send(:process_eligible_to_ineligible_issues!)

          existing_issue1.reload
          existing_issue2.reload

          expect(existing_issue1.ineligible_reason).to eq("untimely")
          expect(existing_issue1.closed_at).to be_within(1.second).of(issue_data[0][:closed_at])
          expect(existing_issue1.contention_reference_id).to be_nil

          expect(existing_issue2.ineligible_reason).to eq("appeal_to_appeal")
          expect(existing_issue2.closed_at).to be_within(1.second).of(issue_data[1][:closed_at])
          expect(existing_issue2.contention_reference_id).to be_nil
        end
      end

      context "when processing 2 issues and one is missing" do
        let!(:existing_issue) do
          create(:request_issue, decision_review: review, reference_id: "1", ineligible_reason: nil)
        end

        let(:issue_data) do
          [
            { reference_id: "1", ineligible_reason: "untimely", closed_at: Time.zone.now },
            { reference_id: "non_existent_id", ineligible_reason: "appeal_to_appeal", closed_at: Time.zone.now }
          ]
        end

        before do
          request_issues_update_event.instance_variable_set(:@eligible_to_ineligible_issue_data, issue_data)
        end

        it "updates existing issues and raises an error for the missing one" do
          expect do
            request_issues_update_event.send(:process_eligible_to_ineligible_issues!)
          end.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError,
                             "Request issue not found for REFERENCE_ID: non_existent_id")

          # Ensure that the existing issue was updated before the error was raised
          existing_issue.reload
          expect(existing_issue.ineligible_reason).to eq("untimely")
          expect(existing_issue.closed_at).to be_within(1.second).of(issue_data[0][:closed_at])
          expect(existing_issue.contention_reference_id).to be_nil
        end
      end
    end

    # 6. Testing #process_ineligible_to_eligible_issues!
    describe "#process_ineligible_to_eligible_issues!" do
      context "when there are ineligible to eligible issues" do
        let!(:existing_issue) do
          create(:request_issue, decision_review: review, reference_id: "2",
                                 ineligible_reason: "untimely", closed_at: Time.zone.now)
        end
        let(:issue_data) { [{ reference_id: "2" }] }

        before do
          request_issues_update_event.instance_variable_set(:@ineligible_to_eligible_issue_data, issue_data)
        end

        it "updates the issue to be eligible by clearing ineligible_reason and closed_at" do
          request_issues_update_event.send(:process_ineligible_to_eligible_issues!)
          existing_issue.reload
          expect(existing_issue.ineligible_reason).to be_nil
          expect(existing_issue.closed_at).to be_nil
        end
      end

      context "when there are no ineligible to eligible issues" do
        before do
          request_issues_update_event.instance_variable_set(:@ineligible_to_eligible_issue_data, [])
        end

        it "does not alter any request issues" do
          expect { request_issues_update_event.send(:process_ineligible_to_eligible_issues!) }
            .not_to change { review.request_issues.pluck(:ineligible_reason) }
        end
      end
    end

    # 7. Testing #process_ineligible_to_ineligible_issues!
    describe "#process_ineligible_to_ineligible_issues!" do
      context "when there are ineligible to ineligible issues with new reasons" do
        let!(:existing_issue) do
          create(:request_issue, decision_review: review, reference_id: "2", ineligible_reason: "untimely",
                                 closed_at: Time.zone.now)
        end
        let(:issue_data) do
          [{ reference_id: "2", ineligible_reason: "higher_level_review_to_higher_level_review",
             closed_at: Time.zone.now }]
        end

        before do
          request_issues_update_event.instance_variable_set(:@ineligible_to_ineligible_issue_data, issue_data)
        end

        it "updates the issue with the new ineligible reason and closed_at date" do
          request_issues_update_event.send(:process_ineligible_to_ineligible_issues!)
          existing_issue.reload
          expect(existing_issue.ineligible_reason).to eq("higher_level_review_to_higher_level_review")
          expect(existing_issue.closed_at).to be_within(1.second).of(issue_data.first[:closed_at])
          expect(existing_issue.contention_reference_id).to be_nil
        end
      end

      context "when there are no ineligible to ineligible issues" do
        before do
          request_issues_update_event.instance_variable_set(:@ineligible_to_ineligible_issue_data, [])
        end

        it "does not alter any request issues" do
          expect { request_issues_update_event.send(:process_ineligible_to_ineligible_issues!) }
            .not_to change { review.request_issues.pluck(:ineligible_reason) }
        end
      end
    end

    # 8. Testing #calculate_added_issues
    describe "#calculate_added_issues" do
      let!(:existing_issue1) { create(:request_issue, decision_review: review, reference_id: "3") }
      let!(:existing_issue2) { create(:request_issue, decision_review: review, reference_id: "4") }

      let(:added_issue_data) do
        [
          {
            reference_id: "3",
            ri_contested_issue_description: "New Issue 3",
            ri_benefit_type: "compensation"
          },
          {
            reference_id: "4",
            ri_contested_issue_description: "New Issue 4",
            ri_benefit_type: "pension"
          }
        ]
      end

      before do
        request_issues_update_event.instance_variable_set(:@added_issue_data, added_issue_data)
      end

      it "fetches existing request issues from the added issue data" do
        added_issues = request_issues_update_event.send(:calculate_added_issues)
        expect(added_issues.size).to eq(2)
        expect(added_issues.map(&:reference_id)).to include("3", "4")
      end
    end
    # rubocop: enable Lint/AmbiguousBlockAssociation
  end
end
