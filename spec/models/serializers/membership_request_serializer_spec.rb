# frozen_string_literal: true

describe MembershipRequestSerializer, :postgres do
  describe "#as_json" do
    let(:camo_org) { VhaCamo.singleton }
    let(:requestor)  { create(:user, full_name: "Avery Johnson", css_id: "CAMOREQUESTOR", email: "test@test.com") }
    let(:note_string) { "Please approve this request quickly." }
    let(:membership_request) do
      create(:membership_request, requestor: requestor, organization: camo_org, note: note_string)
    end

    subject { described_class.new(membership_request) }

    it "renders ready for client consumption" do
      serializable_hash = {
        id: membership_request.id,
        note: note_string,
        status: membership_request.status,
        requestedDate: membership_request.created_at,
        name: camo_org.name,
        url: camo_org.url,
        orgType: camo_org.type,
        orgId: camo_org.id,
        orgName: camo_org.name,
        userName: requestor.full_name,
        userNameWithCssId: "#{requestor.full_name} (#{requestor.css_id})",
        userId: requestor.id
      }

      expect(subject.serializable_hash[:data][:attributes]).to eq(serializable_hash)
    end
  end
end
