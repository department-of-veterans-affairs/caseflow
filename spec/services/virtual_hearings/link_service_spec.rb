# frozen_string_literal: true

describe VirtualHearings::LinkService do
  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  describe ".host_link" do
    context "pin key env variable is missing" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
      end

      it "raises the missing PIN key error" do
        expect { described_class.new.host_link }.to raise_error VirtualHearings::LinkService::PINKeyMissingError
      end
    end

    context "url host env variable is missing" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
      end

      it "raises the missing host error" do
        expect { described_class.new.host_link }.to raise_error VirtualHearings::LinkService::URLHostMissingError
      end
    end

    context "url path env variable is missing" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
      end

      it "raises the missing path error" do
        expect { described_class.new.host_link }.to raise_error VirtualHearings::LinkService::URLPathMissingError
      end
    end

    context "all env variables are present" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
        allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return "0000001"
      end

      it "returns the expected URL", :aggregate_failures do
        uri = URI(described_class.new.host_link)
        expect(uri.scheme).to eq "https"
        expect(uri.host).to eq URL_HOST
        expect(uri.path).to eq "#{URL_PATH}/"

        query = Hash[*uri.query.split(/&|=/)]
        expect(query["conference"]).to eq "BVA0000001@#{URL_HOST}"
        expect(query["name"]).to eq VirtualHearings::LinkService::JUDGE_NAME
        expect(query["pin"]).to eq "3998472"
        expect(query["callType"]).to eq "video"
        expect(query["join"]).to eq "1"
      end
    end
  end

  describe ".guest_link" do
    context "all env variables are present" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
        allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return "0000001"
      end

      it "returns the expected URL", :aggregate_failures do
        uri = URI(described_class.new.guest_link)
        expect(uri.scheme).to eq "https"
        expect(uri.host).to eq URL_HOST
        expect(uri.path).to eq "#{URL_PATH}/"

        query = Hash[*uri.query.split(/&|=/)]
        expect(query["conference"]).to eq "BVA0000001@#{URL_HOST}"
        expect(query["name"]).to eq VirtualHearings::LinkService::GUEST_NAME
        expect(query["pin"]).to eq "7470125694"
        expect(query["callType"]).to eq "video"
        expect(query["join"]).to eq "1"
      end
    end
  end
end
