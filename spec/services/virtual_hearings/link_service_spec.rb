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
      end

      context "the sequence returns '0000001'" do
        before do
          allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return "0000001"
        end

        it "returns the expected URL", :aggregate_failures do
          uri = URI(described_class.new.host_link)
          expect(uri.scheme).to eq "https"
          expect(uri.host).to eq URL_HOST
          expect(uri.path).to eq "#{URL_PATH}/"

          query = Rack::Utils.parse_query(uri.query)
          expect(query["conference"]).to eq "BVA0000001@#{URL_HOST}"
          expect(query["pin"]).to eq "3998472"
          expect(query["callType"]).to eq "video"
        end
      end

      context "the sequence returns sequential values" do
        before do
          allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return("0000099", "0000100", "0000101")
        end

        it "returns different values for different ids", :aggregate_failures do
          host_link = described_class.new.host_link
          expect(described_class.new.host_link).not_to eq host_link
        end

        context "a conference id is passed" do
          it "returns the same value for the same id", :aggregate_failures do
            link_service = described_class.new
            host_link = link_service.host_link
            conference_id = link_service.instance_variable_get(:@conference_id)

            expect(described_class.new.host_link).not_to eq host_link
            expect(described_class.new(conference_id).host_link).to eq host_link
          end
        end
      end
    end
  end

  describe ".guest_link" do
    context "all env variables are present" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
      end

      context "the sequence returns '0000001'" do
        before do
          allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return "0000001"
        end

        it "returns the expected URL", :aggregate_failures do
          uri = URI(described_class.new.guest_link)
          expect(uri.scheme).to eq "https"
          expect(uri.host).to eq URL_HOST
          expect(uri.path).to eq "#{URL_PATH}/"

          query = Rack::Utils.parse_query(uri.query)
          expect(query["conference"]).to eq "BVA0000001@#{URL_HOST}"
          expect(query["pin"]).to eq "7470125694"
          expect(query["callType"]).to eq "video"
        end
      end

      context "the sequence returns sequential values" do
        before do
          allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return("0000099", "0000100", "0000101")
        end

        it "returns different values for different ids", :aggregate_failures do
          guest_link = described_class.new.guest_link
          expect(described_class.new.guest_link).not_to eq guest_link
        end

        context "a conference id is passed" do
          it "returns the same value for the same id", :aggregate_failures do
            link_service = described_class.new
            guest_link = link_service.guest_link
            conference_id = link_service.instance_variable_get(:@conference_id)

            expect(described_class.new.guest_link).not_to eq guest_link
            expect(described_class.new(conference_id).guest_link).to eq guest_link
          end
        end
      end
    end
  end
end
