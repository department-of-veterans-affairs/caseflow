# frozen_string_literal: true

describe IssueModificationRequests::Updater do
  let(:non_admin_user) { create(:user, :admin_intake_role) }
  let(:admin_user) { create(:user, :admin_intake_role, :vha_admin_user) }
  let(:review) { create(:higher_level_review, :with_vha_issue) }
  let(:issue_modification_request) do
    create(:issue_modification_request,
           request_type: original_request_type,
           status: current_status,
           requestor: non_admin_user,
           decision_review: review,
           request_issue: request_issue)
  end
  let(:request_issue) { create(:request_issue) }
  let(:original_request_type) { "addition" }
  let(:status) { "assigned" }
  let(:current_status) { "assigned" }
  let(:edited_request_reason) { "Editing request reason text" }

  describe "non admin updates" do
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
            request_type: "addition",
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
            decision_reason: "New Decision text",
            decision_date: Time.zone.today,
            request_reason: "This is my reason.",
            status: status
          }
        ]
      }
    end

    shared_examples "validated requestor and state" do
      it "should return false and set error message" do
        expect { subject.non_admin_process! }.to raise_error(
          StandardError, COPY::ERROR_MODIFYING_EXISTING_REQUEST
        )
      end
    end

    describe "when new request modifications issues is made" do
      subject do
        described_class.new(
          user: non_admin_user,
          review: review,
          issue_modifications_data: new_modification_requests
        )
      end

      context "and in assigned status" do
        it "should create new issue modifications request record" do
          subject.non_admin_process!
          imr = IssueModificationRequest.first

          expect(IssueModificationRequest.count).to eq(1)
          expect(imr.attributes.symbolize_keys).to include(new_modification_requests[:new].first)
        end
      end

      context "and request is under a different status other than assigned" do
        let(:status) { "cancelled" }

        it "should return false and set error message" do
          expect { subject.non_admin_process! }.to raise_error(
            StandardError, COPY::ERROR_CREATING_NEW_REQUEST
          )
        end
      end
    end

    describe "when editing an existing issue modifications request" do
      subject do
        described_class.new(
          user: non_admin_user,
          review: review,
          issue_modifications_data: edited_modification_requests
        )
      end

      context "and request is still in an assigned status, edited by the same requestor" do
        it "should edit issue modifications request record" do
          subject.non_admin_process!
          issue_modification_request.reload

          expect(issue_modification_request.request_reason).to eq(edited_request_reason)
        end
      end

      context "and request is under a different status other than assigned" do
        let(:current_status) { "cancelled" }

        include_examples "validated requestor and state"
      end

      context "and editing is attempted by a different user than original requestor" do
        before { subject.instance_variable_set(:@user, create(:user)) }

        include_examples "validated requestor and state"
      end
    end

    describe "when cancelling an existing issue modifications request" do
      subject do
        described_class.new(
          user: non_admin_user,
          review: review,
          issue_modifications_data: cancelled_modification_requests
        )
      end

      context "and request is still in an assigned status, cancelled by the same requestor" do
        it "should change issues modification request status to cancelled" do
          subject.non_admin_process!
          issue_modification_request.reload

          expect(issue_modification_request.status).to eq("cancelled")
        end
      end

      context "and request is under a different status other than assigned" do
        let(:current_status) { "approved" }

        include_examples "validated requestor and state"
      end

      context "and cancelling is attempted by a different user than original requestor" do
        before { subject.instance_variable_set(:@user, create(:user)) }

        include_examples "validated requestor and state"
      end
    end
  end

  describe "admin updates" do
    let(:decided_modification_requests) { [generic_request_data] }
    let(:generic_request_data) do
      {
        id: issue_modification_request.id,
        request_type: request_type,
        nonrating_issue_category: "Caregiver | Eligibility",
        decision_review_type: "HigherLevelReview",
        benefit_type: "vha",
        decision_reason: "New Decision text",
        decision_date: 6.days.ago.to_date,
        request_reason: "This is my reason.",
        status: decision_status
      }
    end

    let(:request_type) { "addition" }
    let(:decision_status) { "approved" }
    let(:decided_issue_modification_requests_data) do
      {
        decided: decided_modification_requests
      }
    end

    let(:user) { admin_user }

    before do
      Timecop.freeze(Time.zone.now)
    end

    after do
      Timecop.return
    end

    shared_examples "validate user admin" do
      let(:user) { non_admin_user }
      it "should return an error if the decider is not an admin" do
        expect { subject.non_admin_process! }.to raise_error(
          StandardError, COPY::ERROR_DECIDING_ISSUE_MODIFICATION_REQUEST
        )
      end
    end

    shared_examples "approve request type" do |request_type|
      let(:original_request_type) { request_type.to_s }
      let(:request_type) { request_type.to_s }
      let(:decision_status) { "approved" }

      context "when approving #{request_type} request types" do
        it "should approve the issue #{request_type} request" do
          subject
          expected_attributes(issue_modification_request.reload, generic_request_data)
        end

        it_behaves_like "validate user admin"
      end
    end

    shared_examples "deny request type" do |request_type|
      let(:original_request_type) { request_type.to_s }
      let(:request_type) { request_type.to_s }
      let(:decision_status) { "denied" }

      context "when denying #{request_type} request types" do
        it "should deny the issue #{request_type} request" do
          subject
          expected_attributes(issue_modification_request.reload, generic_request_data)
        end

        it_behaves_like "validate user admin"
      end
    end

    subject do
      described_class.new(
        user: user,
        review: review,
        issue_modifications_data: decided_issue_modification_requests_data
      ).admin_process!
    end

    context "when approving requests" do
      request_types = [:addition, :removal, :modification, :withdrawal]
      request_types.each do |request_type|
        include_examples "approve request type", request_type
      end
    end

    context "when denying requests" do
      request_types = [:addition, :removal, :modification, :withdrawal]
      request_types.each do |request_type|
        include_examples "deny request type", request_type
      end
    end
  end

  def expected_attributes(object_instance, attributes)
    attributes.each do |attribute, expected_value|
      expect(object_instance.send(attribute)).to eq(expected_value)
    end
  end
end
