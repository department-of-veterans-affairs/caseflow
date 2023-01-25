# frozen_string_literal: true

describe MembershipRequest do
  describe "#save" do
    let(:requestor) { create(:user) }
    let(:decisioner) { create(:user) }
    let(:organization) { create(:organization) }

    let(:valid_params) do
      {
        organization_id: organization.id,
        requested_by: requestor.id
      }
    end

    context "when closed_by and closed_at is not present" do
      let(:membership_request) { MembershipRequest.new(valid_params) }
      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
        membership_request.reload

        expect(membership_request.closed_by).to be_nil
        expect(membership_request.closed_at).to be_nil
      end
    end

    context "when closed_by and closed_at is present" do
      let(:decisioner_params) do
        {
          closed_by: decisioner.id,
          closed_at: 1.minute.ago
        }
      end

      let(:membership_request) { MembershipRequest.new(valid_params.merge(decisioner_params)) }

      it "saves to database" do
        expect { membership_request.save }.to change { MembershipRequest.count }.by(1)
        membership_request.reload

        expect(membership_request.closed_by).to be_present
        expect(membership_request.closed_at).to be_present
      end
    end

    context "when organization id is not present" do
      let(:membership_request) { MembershipRequest.new(requested_by: requestor.id) }

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
  end
end
