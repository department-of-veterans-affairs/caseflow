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


  context "Converting conference link to hash" do
    subject { described_class.new(conference_link) }
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

    it "calling serializable_hash return host pin" do
      expect(subject.serializable_hash[:data][:attributes][:host_pin]).to eq(conference_link.host_pin)
    end

    it "calling serializable_hash return alias" do
      expect(subject.serializable_hash[:data][:attributes][:alias]).to eq(conference_link.alias_with_host)
    end
  end

  context "No conference link is passed in" do
    subject { described_class.new(nil) }

    it "conference link serializer exists" do
      expect(subject).not_to eq(nil)
    end

    it "calling serializable_hash returns NoMethodError" do
      expect { subject.serializable_hash[:data][:attributes] }.to raise_error(NoMethodError)
    end
  end
end
