# frozen_string_literal: true

describe ConferenceLink do
  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  context "#create" do
    before do
      allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return "mysecretkey"
      allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return "example.va.gov"
      allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return "/sample"
    end

    let(:hearing_day) do
      create(:hearing_day, id: 1)
    end

    let(:conference_link) do
      create(:conference_link, hearing_day_id: hearing_day.id)
    end

    subject { conference_link }

    it "Confernece link was created and links generated" do
      expect(subject.id).not_to eq(nil)
      expect(subject.host_hearing_link).not_to eq(nil)
      expect(subject.host_pin_long).not_to eq(nil)
      expect(subject.alias_with_host).not_to eq(nil)
    end
  end
end
