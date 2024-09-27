# frozen_string_literal: true

RSpec.shared_context "Enable both conference services" do
  before do
    FeatureToggle.enable!(:pexip_conference_service)
    FeatureToggle.enable!(:webex_conference_service)
  end

  after do
    FeatureToggle.disable!(:pexip_conference_service)
    FeatureToggle.disable!(:webex_conference_service)
  end
end
