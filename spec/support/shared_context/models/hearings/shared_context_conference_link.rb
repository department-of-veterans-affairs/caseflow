# frozen_string_literal: true

RSpec.shared_context "Mock Pexip service env vars" do
  before do
    allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return "mysecretkey"
    allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return "example.va.gov"
    allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return "/sample"
  end
end

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
