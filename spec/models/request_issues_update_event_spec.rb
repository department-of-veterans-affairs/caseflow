# frozen_string_literal: true

RSpec.describe RequestIssuesUpdateEvent, type: :model do
  let(:user) { create(:user) }
  let(:review) { create(:appeal) }

  let(:parser) do
    json_path = Rails.root.join("app",
                                "services", "events", "decision_review_updated",
                                "decision_review_updated_example.json")
    json_content = File.read(json_path)
    # Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, JSON.parse(json_content))
    Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new(nil, JSON.parse(json_content))
  end

  subject do
    described_class.new(
      user: user,
      review: review,
      parser: parser
      # added_issue_data: parser.added_issues,
      # removed_issue_data: parser.removed_issues,
      # edited_issue_data: parser.updated_issues,
      # withdrawn_issue_data: parser.withdrawn_issues
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
      expect(subject).to receive(:calculate_removed_issues).and_return(parser.removed_issues)
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
      expect(added_issues.size).to eq(2) # Expecting two issues to be processed
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

  context "when handling errors in #process_edited_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@edited_issue_data, [{ reference_id: invalid_reference_id }])
    end

    context "when a request issue is not found" do
      before do
        allow(RequestIssue).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
        expect { subject.perform! }.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError, "Request issue not found for REFERENCE_ID: #{invalid_reference_id}")
      end
    end
  end

  context "when handling errors in #process_removed_issues!" do
    let(:invalid_reference_id) { "12345" }

    before do
      subject.instance_variable_set(:@removed_issue_data, [{ reference_id: invalid_reference_id }])
    end

    context "when a request issue is not found" do
      before do
        allow(review.request_issues).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
        expect { subject.perform! }.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError, "Request issue not found for REFERENCE_ID: #{invalid_reference_id}")
      end
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
        expect { subject.perform! }.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError, "Request issue not found for REFERENCE_ID: #{invalid_reference_id}")
      end
    end
  end

  context "when handling errors in #process_eligible_to_ineligible_issues!" do
    let(:invalid_reference_id) { "12345" }
    let(:eligible_to_ineligible_issue) { [{ reference_id: invalid_reference_id, ineligible_reason: "higher_level_review_to_higher_level_review" }] }


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
    let(:ineligible_to_eligible_issue) { [{ reference_id: invalid_reference_id, ineligible_reason: nil }] }

    before do
      subject.instance_variable_set(:@ineligible_to_eligible_issue_data, [{ reference_id: invalid_reference_id }])

      allow_any_instance_of(RequestIssue).to receive(:closed_at).and_return(nil)
      allow_any_instance_of(RequestIssue).to receive(:save!).and_return(true)
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

  context "when handling errors in #process_ineligible_to_ineligible_issues!" do
    let(:invalid_reference_id) { "12345" }
    let(:ineligible_issue_data) { [{ reference_id: invalid_reference_id, ineligible_reason: "appeal_to_appeal" }] }

    before do
      subject.instance_variable_set(:@ineligible_to_ineligible_issue_data, [{ reference_id: invalid_reference_id }])

      allow_any_instance_of(RequestIssue).to receive(:closed_at).and_return(nil)
      allow_any_instance_of(RequestIssue).to receive(:save!).and_return(true)
    end

    context "when a request issue is not found" do
      before do
        allow(RequestIssue).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it "raises a DecisionReviewUpdateMissingIssueError with the correct message" do
        expect { subject.perform! }.to raise_error(Caseflow::Error::DecisionReviewUpdateMissingIssueError, "Request issue not found for REFERENCE_ID: #{invalid_reference_id}")
      end
    end
  end
end
# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe RequestIssuesUpdateEvent, type: :model do
#   let(:user) { create(:user) }
#   let(:review) { create(:appeal) }
#   let(:parser) do
#     json_path = Rails.root.join("app", "services", "events", "decision_review_updated", "decision_review_updated_example.json")
#     json_content = File.read(json_path)
#     Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new(nil, JSON.parse(json_content))
#   end

#   let(:request_issues_update_event) do
#     RequestIssuesUpdateEvent.new(
#       user: user,
#       review: review,
#       parser: parser
#     )
#   end

#   describe '#perform!' do
#     context 'when validation passes and issues are processed' do
#       before do
#         allow(request_issues_update_event).to receive(:validate_before_perform).and_return(true)
#         allow(request_issues_update_event).to receive(:processed?).and_return(false)
#         allow(review).to receive(:mark_rating_request_issues_to_reassociate!)
#         allow(request_issues_update_event).to receive(:process_job)
#       end

#       it 'processes issues and updates review' do
#         expect(request_issues_update_event).to receive(:process_issues!)
#         expect(request_issues_update_event).to receive(:update!)

#         expect(request_issues_update_event.perform!).to be_truthy
#       end
#     end

#     context 'when validation fails' do
#       before do
#         allow(request_issues_update_event).to receive(:validate_before_perform).and_return(false)
#       end

#       it 'does not process issues' do
#         expect(request_issues_update_event.perform!).to be_falsey
#         expect(request_issues_update_event).not_to receive(:process_issues!)
#       end
#     end

#     context 'when already processed' do
#       before do
#         allow(request_issues_update_event).to receive(:processed?).and_return(true)
#       end

#       it 'does not process issues' do
#         expect(request_issues_update_event.perform!).to be_falsey
#         expect(request_issues_update_event).not_to receive(:process_issues!)
#       end
#     end
#   end

#   describe '#process_issues!' do
#     it 'calls individual issue processing methods' do
#       expect(request_issues_update_event).to receive(:process_added_issues!)
#       expect(request_issues_update_event).to receive(:process_removed_issues!)
#       expect(request_issues_update_event).to receive(:process_withdrawn_issues!)
#       expect(request_issues_update_event).to receive(:process_edited_issues!)
#       expect(request_issues_update_event).to receive(:process_eligible_to_ineligible_issues!)
#       expect(request_issues_update_event).to receive(:process_ineligible_to_eligible_issues!)
#       expect(request_issues_update_event).to receive(:process_ineligible_to_ineligible_issues!)

#       request_issues_update_event.process_issues!
#     end
#   end

#   describe '#process_added_issues!' do
#     it 'creates issues from added_issue_data' do
#       added_issues = request_issues_update_event.added_issues
#       expect(review).to receive(:create_issues!).with(added_issues, request_issues_update_event)
#       request_issues_update_event.process_added_issues!
#     end
#   end

#   describe '#removed_issues' do
#     context 'when removed_issue_data is present' do
#       it 'returns removed issues based on reference_id' do
#         removed_issue = create(:request_issue, review: review)
#         allow(review).to receive(:request_issues).and_return([removed_issue])

#         expect(request_issues_update_event.removed_issues).to include(removed_issue)
#       end
#     end

#     context 'when removed_issue_data is empty' do
#       it 'returns nil' do
#         request_issues_update_event.instance_variable_set(:@removed_issue_data, [])
#         expect(request_issues_update_event.removed_issues).to be_nil
#       end
#     end
#   end

#   describe '#all_updated_issues' do
#     it 'returns an array of all issue types' do
#       added_issues = create_list(:request_issue, 2, review: review)
#       removed_issues = create_list(:request_issue, 2, review: review)
#       withdrawn_issues = create_list(:request_issue, 1, review: review)
#       edited_issues = create_list(:request_issue, 1, review: review)

#       allow(request_issues_update_event).to receive(:added_issues).and_return(added_issues)
#       allow(request_issues_update_event).to receive(:removed_issues).and_return(removed_issues)
#       allow(request_issues_update_event).to receive(:withdrawn_issues).and_return(withdrawn_issues)
#       allow(request_issues_update_event).to receive(:edited_issues).and_return(edited_issues)

#       expect(request_issues_update_event.all_updated_issues.size).to eq(6)
#     end
#   end
# end
