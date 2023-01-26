# frozen_string_literal: true

describe MembershipRequest do
  describe "#save" do
    let(:requestor) { create(:user) }
    let(:decider) { create(:user) }
    let(:organization) { create(:organization) }

    let(:valid_params) do
      {
        organization_id: organization.id,
        requestor: requestor
      }
    end

    context "when decider and decided_at is not present" do
      let(:membership_request) { MembershipRequest.new(valid_params) }
      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
        membership_request.reload

        expect(membership_request.decider).to be_nil
        expect(membership_request.decided_at).to be_nil
      end
    end

    context "when decided_by_id and decided_at is present" do
      let(:decider_params) do
        {
          decider: decider,
          decided_at: 1.minute.ago
        }
      end

      let(:membership_request) { MembershipRequest.new(valid_params.merge(decider_params)) }

      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
        membership_request.reload

        expect(membership_request.decider).to be_present
        expect(membership_request.decided_at).to be_present
      end
    end

    context "when organization id is not present" do
      let(:membership_request) { MembershipRequest.new(requestor: requestor) }

      it "should not save to database" do
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end

    context "when requestor id is not present" do
      let(:membership_request) { MembershipRequest.new(organization_id: organization.id) }

      it "should not save to database" do
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end

    context "when status is not present" do
      let(:membership_request) { MembershipRequest.new(valid_params) }

      it "should not save to database" do
        membership_request.status = nil
        membership_request.valid?

        expect(membership_request.errors.full_messages).to be_present
      end
    end
  end
end
