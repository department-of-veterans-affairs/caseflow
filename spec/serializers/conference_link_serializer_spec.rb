# frozen_string_literal: true

describe ConferenceLinkSerializer, :all_dbs do
  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  let(:hearing_day) { create(:hearing_day) }
  let(:conference_link) { create(:conference_link, hearing_day_id: hearing_day.id) }
  
  subject { described_class.new(conference_link) }

  context "Converting conference link to hash" do

    before do
      allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return "mysecretkey"
      allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return "example.va.gov"
      allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return "/sample"
    end

    it "calling serializable_hash gets result" do
      expect(subject.serializable_hash[:data][:attributes]).not_to eq(nil)
    end

    it "calling serializable_hash return host link" do
      expect(subject.serializable_hash[:data][:attributes][:host_link]).to eq(conference_link.host_link)
    end
  end
end