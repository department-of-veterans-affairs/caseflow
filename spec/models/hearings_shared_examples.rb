# frozen_string_literal: true

shared_context "Pexip and Webex Users" do
  let!(:pexip_user) do
    create(:user, css_id: "PEXIP_USER").tap { |user| user.meeting_type.update!(service_name: "pexip") }
  end
  let!(:webex_user) do
    create(:user, css_id: "WEBEX_USER").tap { |user| user.meeting_type.update!(service_name: "webex") }
  end
end

shared_examples "Conference provider values are transferred between base entity and new hearings" do
  subject { hearing.conference_provider }

  context "Pexip user schedules the hearing" do
    let(:hearing) { create(hearing_type, adding_user: pexip_user) }

    it "Hearing scheduled by Pexip user is assigned a Pexip conference provider" do
      is_expected.to eq pexip_user.conference_provider
      is_expected.to eq "pexip"
    end
  end

  context "Webex user schedules the hearing" do
    let(:hearing) { create(hearing_type, adding_user: webex_user) }

    it "Hearing scheduled by Webex user is assigned a User conference provider" do
      is_expected.to eq webex_user.conference_provider
      is_expected.to eq "webex"
    end
  end
end
