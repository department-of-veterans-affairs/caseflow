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
  let(:hearing) { create(:hearing) }

  shared_examples "Serialized conferenced link attributes meet expectations" do
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

  context "Converting conference link to hash" do
    subject { described_class.new(conference_link) }

    context "With a Pexip conference link" do
      let(:conference_link) { create(:pexip_conference_link, hearing_day: hearing_day) }

      include_examples "Serialized conferenced link attributes meet expectations"
    end

    context "With a Webex conference link" do
      let(:conference_link) { create(:webex_conference_link, hearing: hearing) }

      include_examples "Serialized conferenced link attributes meet expectations"
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
