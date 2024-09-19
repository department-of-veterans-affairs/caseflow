# frozen_string_literal: true

describe PexipConferenceLink do
  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
  end

  context "#create with errors" do
    context "pin key env variable is missing" do
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing PIN key error" do
        RequestStore[:current_user] = user
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return(nil)
        expect do
          described_class.create(hearing_day: hearing_day)
        end.to raise_error VirtualHearings::PexipLinkService::PINKeyMissingError
      end
    end

    context "url host env variable is missing" do
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing host error" do
        RequestStore[:current_user] = user
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return(nil)
        expect do
          described_class.create(hearing_day: hearing_day)
        end.to raise_error VirtualHearings::PexipLinkService::URLHostMissingError
      end
    end

    context "url path env variable is missing" do
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing path error" do
        RequestStore[:current_user] = user
        allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return(nil)
        expect do
          described_class.create(hearing_day: hearing_day)
        end.to raise_error VirtualHearings::PexipLinkService::URLPathMissingError
      end
    end

    context "all env variables are missing" do
      let(:hearing_day) { create(:hearing_day) }
      let(:user) { create(:user) }
      it "raises the missing PIN key error" do
        allow(ENV).to receive(:[]).with(anything).and_return(nil)
        RequestStore[:current_user] = user
        expect do
          described_class.create(hearing_day: hearing_day)
        end.to raise_error VirtualHearings::PexipLinkService::PINKeyMissingError
      end
    end
  end

  context "#create" do
    let(:hearing_day) do
      create(:hearing_day, id: 1)
    end

    let(:conference_link) do
      create(:pexip_conference_link, hearing_day_id: hearing_day.id)
    end

    subject { conference_link }

    it "Conference link was created and links generated" do
      expect(subject.id).not_to eq(nil)
      expect(subject.host_link).not_to eq(nil)
      expect(subject.host_pin_long).not_to eq(nil)
      expect(subject.alias_with_host).not_to eq(nil)
      expect(subject.alias_name).not_to eq(nil)
      expect(subject.created_by_id).not_to eq(nil)
      expect(subject.host_pin).to eq(subject.host_pin_long)
      expect(subject.host_link).to eq(subject.host_link)
      expect(subject.guest_hearing_link).to eq(subject.guest_hearing_link)
      expect(subject.guest_pin_long).to eq(subject.guest_pin_long)
      expect(subject.updated_by_id).not_to eq(nil)
    end
  end

  context "update conference day" do
    let(:hearing_day) do
      create(:hearing_day, id: 1)
    end

    let(:conference_link) do
      create(:pexip_conference_link, hearing_day_id: hearing_day.id)
    end

    let(:conference_link_hash) do
      {
        host_pin: 12_345_678,
        host_pin_long: "12345678",
        guest_pin_long: "123456789",
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
      expect(updated_conference_link.guest_pin_long).to eq("123456789")
      expect(updated_conference_link.created_at).to eq(DateTime.new(2022, 3, 15, 10, 15, 30))
      expect(updated_conference_link.updated_at).to eq(DateTime.new(2022, 4, 27, 11, 20, 35))
      expect(updated_conference_link.updated_by_id).not_to eq(nil)
      expect(updated_conference_link.created_by_id).not_to eq(nil)
    end
  end

  describe "#guest_pin" do
    include_context "Enable both conference services"

    let(:hearing_day) { create(:hearing_day) }

    let!(:user) { RequestStore.store[:current_user] = User.system_user }

    let(:conference_link) { hearing_day.conference_link }

    context "guest_pin_long property already has a pin as a value" do
      it "Returns the guest_pin for the conference_link" do
        expect(conference_link.guest_pin_long).to eq(conference_link.guest_pin)
      end
    end
    context "guest_pin_long property has a value of nil." do
      it "checks if property is nil. If so, a new pin is created. " do
        conference_link.update!(guest_pin_long: nil)
        expect(conference_link.guest_pin).not_to eq(nil)
      end
    end
  end

  describe "#guest_link" do
    before do
      allow_any_instance_of(VirtualHearings::PexipLinkService).to receive(:conference_id)
        .and_return expected_conference_id
      allow_any_instance_of(VirtualHearings::PexipLinkService).to receive(:guest_pin).and_return expected_pin
    end
    let(:hearing_day) { create(:hearing_day) }
    let!(:user) { RequestStore.store[:current_user] = User.system_user }

    let(:conference_link) do
      create(:pexip_conference_link,
             hearing_day_id: hearing_day.id,
             guest_hearing_link: existing_url,
             guest_pin_long: nil)
    end

    let(:expected_pin) { "7470125694" }
    let(:expected_conference_id) { "0000001" }

    let(:existing_url) do
      "https://example.va.gov/sample/?" \
      "conference=BVA#{expected_conference_id}@example.va.gov&" \
      "pin=#{expected_pin}&callType=video"
    end

    context "guest_hearing_link property already has a link/string as a value" do
      it "Returns the guest_pin for the conference_link" do
        conference_link.guest_link
        expect(conference_link.guest_hearing_link).to eq(existing_url)
      end
    end
    context "guest_hearing_link property already has a nil value" do
      it "creates and returns the updated guest_hearing_link property" do
        conference_link.update!(guest_hearing_link: nil)
        conference_link.guest_link
        expect(conference_link.guest_hearing_link).to eq(existing_url)
      end
    end
    context "If alias_name(aliased for the alias property) is nil AND guest_hearing_link is nil "\
      "and alias_with_host is NOT nil" do
      it "creates a guest_hearing_link updates the property and updates the alias property" do
        conference_link.update!(alias: nil, guest_hearing_link: nil, alias_with_host: "BVA0000001@example.va.gov")
        conference_link.guest_link
        expect(conference_link.guest_hearing_link).to eq(existing_url)
      end
    end
  end
end
