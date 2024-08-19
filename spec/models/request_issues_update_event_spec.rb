# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestIssuesUpdateEvent, type: :model do
  let(:user) { create(:user) }
  let(:review) { create(:appeal) }
  let(:parser) { instance_double("Events::DecisionReviewUpdated::DecisionReviewUpdatedParser", added_issues: added_issues_data, removed_issues: removed_issues_data, updated_issues: edited_issues_data, withdrawn_issues: withdrawn_issues_data) }
  let(:added_issues_data) { [{ id: 1, contested_issue_description: "Added Issue" }] }
  let(:removed_issues_data) { [{ id: 2, contested_issue_description: "Removed Issue" }] }
  let(:edited_issues_data) { [{ id: 3, contested_issue_description: "Edited Issue" }] }
  let(:withdrawn_issues_data) { [{ id: 4, contested_issue_description: "Withdrawn Issue" }] }

  subject do
    described_class.new(
      user: user,
      review: review,
      added_issues_data: parser.added_issues,
      removed_issues_data: parser.removed_issues,
      edited_issues_data: parser.updated_issues,
      withdrawn_issues_data: parser.withdrawn_issues
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

    context "when already processed" do
      it "returns false" do
        allow(subject).to receive(:processed?).and_return(true)
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
      expect(subject).to receive(:calculate_added_issues).and_return(added_issues_data)
      subject.added_issues
    end
  end

  describe "#removed_issues" do
    it "calculates the removed issues" do
      expect(subject).to receive(:calculate_removed_issues).and_return(removed_issues_data)
      subject.removed_issues
    end
  end

  describe "#withdrawn_issues" do
    it "calculates or fetches the withdrawn issues" do
      allow(subject).to receive(:withdrawn_request_issue_ids).and_return(nil)
      expect(subject).to receive(:calculate_withdrawn_issues).and_return(withdrawn_issues_data)
      subject.withdrawn_issues
    end
  end

  describe "#validate_before_perform" do
    context "when there are no changes" do
      it "sets error_code to :no_changes and returns false" do
        allow(subject).to receive(:changes?).and_return(false)
        expect(subject.validate_before_perform).to be false
        expect(subject.error_code).to eq(:no_changes)
      end
    end

    context "when there is a previous update still processing" do
      it "sets error_code to :previous_update_not_done_processing and returns false" do
        allow(subject).to receive(:changes?).and_return(true)
        allow(RequestIssuesUpdate).to receive_message_chain(:where, :where, :processable, :exists?).and_return(true)
        expect(subject.validate_before_perform).to be false
        expect(subject.error_code).to eq(:previous_update_not_done_processing)
      end
    end
  end
end
