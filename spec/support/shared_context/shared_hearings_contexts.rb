# frozen_string_literal: true

shared_context "VSO versus Hearings Team user" do
  let(:hearings_user) { create(:user, roles: ["Hearing Prep"]) }
  let(:vso_participant_id) { "123456789" }
  let(:vso_org) do
    create(:vso, name: "VSO Org", role: "VSO", url: "vso-url", participant_id: vso_participant_id)
  end
  let(:vso_user) { create(:user, :vso_role, email: "vso_user@vso.com") }
end
