# frozen_string_literal: true

describe ConferenceLink do
  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  context "#create with errors" do
    context "pin key env variable is missing" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
      end
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing PIN key error" do
        RequestStore[:current_user] = user
        expect { described_class.create(hearing_day_id: hearing_day.id) }.to raise_error VirtualHearings::LinkService::PINKeyMissingError
      end
    end

    context "url host env variable is missing" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
      end
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing host error" do
        RequestStore[:current_user] = user
        expect { described_class.create(hearing_day_id: hearing_day.id) }.to raise_error VirtualHearings::LinkService::URLHostMissingError
      end
    end

    context "url path env variable is missing" do
      before do
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
      end
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing path error" do
        RequestStore[:current_user] = user
        expect { described_class.create(hearing_day_id: hearing_day.id) }.to raise_error VirtualHearings::LinkService::URLPathMissingError
      end
    end

    context "all env variables are missing" do
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing PIN key error" do
        RequestStore[:current_user] = user
        expect { described_class.create(hearing_day_id: hearing_day.id) }.to raise_error VirtualHearings::LinkService::PINKeyMissingError
      end
    end
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

    it "Conference link was created and links generated" do
      expect(subject.id).not_to eq(nil)
      expect(subject.host_link).not_to eq(nil)
      expect(subject.host_pin_long).not_to eq(nil)
      expect(subject.alias_with_host).not_to eq(nil)
      expect(subject.alias_name).to eq(nil)
      expect(subject.created_by_id).not_to eq(nil)
      expect(subject.host_pin).to eq(subject.host_pin_long)
      expect(subject.host_link).to eq(subject.host_link)
      expect(subject.updated_by_id).not_to eq(nil)
    end
  end

  context "update conference day" do
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

    let(:conference_link_hash) do
      {
        host_pin: 12_345_678,
        host_pin_long: "12345678",
        created_at: DateTime.new(2022, 3, 15, 10, 15, 30),
        updated_at: DateTime.new(2022, 4, 27, 11, 20, 35)
      }
    end

    subject { conference_link.update!(conference_link_hash) }

    it "Conference link was updated" do
      subject

      updated_conference_link = ConferenceLink.find(conference_link.id).reload
      expect(updated_conference_link.host_pin).to eq("12345678")
      expect(updated_conference_link.host_pin_long).to eq("12345678")
      expect(updated_conference_link.created_at).to eq(DateTime.new(2022, 3, 15, 10, 15, 30))
      expect(updated_conference_link.updated_at).to eq(DateTime.new(2022, 4, 27, 11, 20, 35))
      expect(updated_conference_link.updated_by_id).not_to eq(nil)
      expect(updated_conference_link.created_by_id).not_to eq(nil)
    end
  end
end
