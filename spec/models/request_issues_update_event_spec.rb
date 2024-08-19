# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestIssueUpdateEvent, :all_dbs, type: :model do
  before do
    Time.zone = "America/New_York"
    Timecop.freeze(Time.utc(2018, 5, 20))
  end

  let(:review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }
  let!(:veteran) { create(:veteran) }
  let(:user) { create(:user) }
  let(:edit_user) { create(:user) }

  let(:rating_end_product_establishment) do
    create(
      :end_product_establishment,
      veteran_file_number: veteran.file_number,
      source: review,
      code: "030HLRR",
      user_id: user.id
    )
  end

  let(:request_issue_contentions) do
    [
      Generators::Contention.build(
        claim_id: rating_end_product_establishment.reference_id,
        text: "Service connection for PTSD was granted at 10 percent",
        start_date: Time.zone.now,
        submit_date: 8.days.ago
      ),
      Generators::Contention.build(
        claim_id: rating_end_product_establishment.reference_id,
        text: "Service connection for left knee immobility was denied",
        start_date: Time.zone.now,
        submit_date: 8.days.ago
      )
    ]
  end

  let!(:existing_request_issue) do
    RequestIssue.new(
      decision_review: review,
      contested_rating_issue_profile_date: Time.zone.local(2017, 4, 5),
      contested_rating_issue_reference_id: "issue1",
      contention_reference_id: request_issue_contentions[0].id,
      contested_issue_description: request_issue_contentions[0].text,
      rating_issue_associated_at: 5.days.ago
    )
  end

  let!(:existing_request_issues) { [existing_request_issue] }

  let(:request_issues_data) { [] }

  let(:request_issue_update_event) do
    RequestIssueUpdateEvent.new(
      user: user,
      review: review,
      added_issues_data: added_issues_data,
      removed_issues_data: removed_issues_data,
      edited_issues_data: edited_issues_data,
      withdrawn_issues_data: withdrawn_issues_data
    )
  end

  let(:added_issues_data) { [] }
  let(:removed_issues_data) { [] }
  let(:edited_issues_data) { [] }
  let(:withdrawn_issues_data) { [] }

  before do
    review.create_issues!(existing_request_issues)
  end

  describe "#perform!" do
    subject { request_issue_update_event.perform! }

    context "when there are no changes" do
      it "does not process the event" do
        expect(subject).to be_falsey
        expect(request_issue_update_event.error_code).to eq(:no_changes)
      end
    end

    context "when there are changes" do
      let(:added_issues_data) do
        [{
          rating_issue_reference_id: "issue3",
          rating_issue_profile_date: Time.zone.local(2017, 11, 7),
          decision_text: "Service connection for cancer was denied"
        }]
      end

      it "processes the event and returns true" do
        expect(subject).to be_truthy
        expect(review.request_issues.count).to eq(2)  # original + new issue
      end

      it "updates the review with the correct issue IDs" do
        subject
        expect(request_issue_update_event.before_request_issue_ids).to contain_exactly(existing_request_issue.id)
        expect(request_issue_update_event.after_request_issue_ids).to include(RequestIssue.last.id)
      end
    end
  end

  describe "#added_issues" do
    subject { request_issue_update_event.added_issues }

    context "when issues are added" do
      let(:added_issues_data) do
        [{
          rating_issue_reference_id: "issue3",
          rating_issue_profile_date: Time.zone.local(2017, 11, 7),
          decision_text: "Service connection for cancer was denied"
        }]
      end

      it "returns the added issues" do
        expect(subject.size).to eq(1)
        expect(subject.first.contested_rating_issue_reference_id).to eq("issue3")
      end
    end

    context "when no issues are added" do
      it { is_expected.to be_empty }
    end
  end

  describe "#removed_issues" do
    subject { request_issue_update_event.removed_issues }

    context "when issues are removed" do
      let(:removed_issues_data) { [{ id: existing_request_issue.id }] }

      it "returns the removed issues" do
        expect(subject.size).to eq(1)
        expect(subject.first.id).to eq(existing_request_issue.id)
      end
    end

    context "when no issues are removed" do
      it { is_expected.to be_empty }
    end
  end

  describe "#withdrawn_issues" do
    subject { request_issue_update_event.withdrawn_issues }

    context "when issues are withdrawn" do
      let(:withdrawn_issues_data) { [{ id: existing_request_issue.id }] }

      it "returns the withdrawn issues" do
        expect(subject.size).to eq(1)
        expect(subject.first.id).to eq(existing_request_issue.id)
      end
    end

    context "when no issues are withdrawn" do
      it { is_expected.to be_empty }
    end
  end

  describe "#process_issues!" do
    before { allow(request_issue_update_event).to receive(:process_removed_issues!) }

    it "calls all the necessary methods to process issues" do
      expect(request_issue_update_event).to receive(:process_removed_issues!)
      expect(request_issue_update_event).to receive(:process_legacy_issues!)
      expect(request_issue_update_event).to receive(:process_withdrawn_issues!)
      expect(request_issue_update_event).to receive(:process_edited_issues!)

      request_issue_update_event.send(:process_issues!)
    end
  end

  describe "#validate_before_perform" do
    context "when there are no changes" do
      it "sets an error code and returns false" do
        expect(request_issue_update_event.send(:validate_before_perform)).to be_falsey
        expect(request_issue_update_event.error_code).to eq(:no_changes)
      end
    end

    context "when there is a previous update not done processing" do
      it "sets an error code and returns false" do
        allow(RequestIssuesUpdate).to receive_message_chain(:where, :where, :processable, :exists?).and_return(true)
        expect(request_issue_update_event.send(:validate_before_perform)).to be_falsey
        expect(request_issue_update_event.error_code).to eq(:previous_update_not_done_processing)
      end
    end
  end

  describe "#edit_contention_text" do
    let(:edited_issues_data) do
      [{ id: existing_request_issue.id, edited_description: "New description" }]
    end

    it "updates the contention text of the edited issue" do
      request_issue_update_event.perform!
      expect(existing_request_issue.reload.edited_description).to eq("New description")
    end
  end

  describe "#edit_decision_date" do
    let(:edited_issues_data) do
      [{ id: existing_request_issue.id, decision_date: Time.zone.now }]
    end

    it "updates the decision date of the edited issue" do
      request_issue_update_event.perform!
      expect(existing_request_issue.reload.decision_date).to eq(Time.zone.now.to_date)
    end
  end
end
