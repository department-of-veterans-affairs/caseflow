# frozen_string_literal: true

describe NonAdmin::IssueModificationRequestsUpdater do
  let(:non_admin_requestor) { create(:user, :admin_intake_role, :vha_intake_admin) }
  let(:review) { create(:higher_level_review, :with_vha_issue) }
  let(:issue_modification_request) { create(:issue_modification_request, requestor: non_admin_requestor) }
  let(:status) { "assigned" }
  let(:edited_request_reason) { "Editing request reason text" }

  let(:cancelled_modification_requests) do
    {
      cancelled: [
        {
          id: issue_modification_request.id,
          status: status
        }
      ],
      edited: [],
      new: []
    }
  end

  let(:edited_modification_requests) do
    {
      cancelled: [],
      edited: [
        {
          id: issue_modification_request.id,
          nonrating_issue_category: "Caregiver | Other",
          nonrating_issue_description: "Decision text",
          decision_date: "2024-01-30",
          request_reason: edited_request_reason,
          status: status
        }
      ],
      new: []
    }
  end

  let(:new_modification_requests) do
    {
      cancelled: [],
      edited: [],
      new: [
        {
          request_type: "addition",
          nonrating_issue_category: "Caregiver | Eligibility",
          decision_review_id: review.id,
          request_issue_id: nil,
          decision_review_type: "HigherLevelReview",
          benefit_type: "VHA",
          decider_reason: "New Decision text",
          decision_date: "2024-01-30",
          request_reason: "This is my reason.",
          requestor_id: non_admin_requestor.id,
          status: status
        }
      ]
    }
  end

  describe "when new request modifications issues is made" do
    subject do
      described_class.new(
        current_user: non_admin_requestor,
        review: review,
        issue_modifications_data: new_modification_requests
      )
    end

    context "and in assigned status" do
      it "should create new issue modifications request record" do
        subject.process!
        expect(IssueModificationRequest.count).to eq(1)
        expect(subject.success?).to be_truthy
      end
    end

    context "and request is under a different status other than assigned" do
      let(:status) { "cancelled" }

      it "should return false and set error message" do
        subject.process!
        expect(subject.success?).to be_falsy

        expect(subject.error_code).to eq(
          NonAdmin::IssueModificationRequestsUpdater::NEW_REQUEST_ERROR
        )
      end
    end
  end

  describe "when editing an exisitng issue modifications request" do
    subject do
      described_class.new(
        current_user: non_admin_requestor,
        review: review,
        issue_modifications_data: edited_modification_requests
      )
    end

    context "and request is still in an assigned status, edited by the same requestor" do
      it "should edit issue modifications request record" do
        subject.process!
        issue_modification_request.reload

        expect(subject.success?).to be_truthy
        expect(issue_modification_request.request_reason).to eq(edited_request_reason)
      end
    end

    context "and request is under a different status other than assigned" do
      let(:status) { "cancelled" }

      it "should return false and set error message" do
        subject.process!
        issue_modification_request.reload

        expect(subject.success?).to be_falsy
        expect(subject.error_code).to eq(
          NonAdmin::IssueModificationRequestsUpdater::MODIFICATION_ERROR
        )
      end
    end

    context "and editing is attempted by a different user than original requestor" do
      before { subject.instance_variable_set(:@current_user, create(:user)) }

      it "should return false and set error message" do
        subject.process!
        issue_modification_request.reload

        expect(subject.success?).to be_falsy
        expect(subject.error_code).to eq(
          NonAdmin::IssueModificationRequestsUpdater::MODIFICATION_ERROR
        )
      end
    end
  end

  describe "when cancelling an exisitng issue modifications request" do
    subject do
      described_class.new(
        current_user: non_admin_requestor,
        review: review,
        issue_modifications_data: cancelled_modification_requests
      )
    end

    context "and request is still in an assigned status, cancelled by the same requestor" do
      it "should change issues modification request status to cancelled" do
        subject.process!
        issue_modification_request.reload

        expect(subject.success?).to be_truthy
        expect(issue_modification_request.status).to eq("cancelled")
      end
    end

    context "and request is under a different status other than assigned" do
      let(:status) { "approved" }

      it "should return false and set error message" do
        subject.process!
        issue_modification_request.reload

        expect(subject.success?).to be_falsy
        expect(subject.error_code).to eq(
          NonAdmin::IssueModificationRequestsUpdater::MODIFICATION_ERROR
        )
      end
    end

    context "and cancelling is attempted by a different user than original requestor" do
      before { subject.instance_variable_set(:@current_user, create(:user)) }

      it "should return false and set error message" do
        subject.process!
        issue_modification_request.reload

        expect(subject.success?).to be_falsy
        expect(subject.error_code).to eq(
          NonAdmin::IssueModificationRequestsUpdater::MODIFICATION_ERROR
        )
      end
    end
  end
end
