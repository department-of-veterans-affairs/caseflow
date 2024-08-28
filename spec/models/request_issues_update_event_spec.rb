# frozen_string_literal: true

RSpec.describe RequestIssuesUpdateEvent, type: :model do
  let(:user) { create(:user) }
  let(:review) { create(:appeal) }

  let(:parser) do
    json_path = Rails.root.join("app",
                                "services", "events", "decision_review_updated",
                                "decision_review_updated_example.json")
    json_content = File.read(json_path)
    Events::DecisionReviewUpdated::DecisionReviewUpdatedParser.new({}, JSON.parse(json_content))
  end

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
        subject.instance_variable_set(:@added_issues_data, parser.added_issues)
        subject.instance_variable_set(:@removed_issues_data, [])
        subject.instance_variable_set(:@edited_issues_data, [])
        subject.instance_variable_set(:@withdrawn_issues_data, [])

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
    let(:multiple_issues_data) { parser.added_issues + parser.added_issues } # Simulating multiple issues

    before do
      subject.instance_variable_set(:@added_issues_data, multiple_issues_data)
    end

    it "processes all added issues and returns the correct count" do
      added_issues = subject.send(:calculate_added_issues)
      expect(added_issues.size).to eq(2) # Expecting two issues to be processed
    end
  end

  context "when multiple types of issues are present" do
    before do
      subject.instance_variable_set(:@added_issues_data, parser.added_issues)
      subject.instance_variable_set(:@removed_issues_data, parser.removed_issues)
      subject.instance_variable_set(:@edited_issues_data, parser.updated_issues)
      subject.instance_variable_set(:@withdrawn_issues_data, parser.withdrawn_issues)

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
end
