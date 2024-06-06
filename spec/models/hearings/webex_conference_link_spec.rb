# frozen_string_literal: true

describe WebexConferenceLink do
  let(:hearing_day) { create(:hearing_day, id: 1) }
  let(:link) { create(:webex_conference_link, hearing_day_id: hearing_day.id) }

  describe "method calls" do
    it "soft removal of link" do
      link
      expect(ConferenceLink.all.size).to eq(1)
      link.soft_removal_of_link
      expect(link.conference_deleted).to eq(true)
      expect(ConferenceLink.all.size).to eq(0)
    end

    context "#create" do
      it "Conference link was created and links generated" do
        expect(link.id).not_to eq(nil)
        expect(link.host_link).not_to eq(nil)
        expect(link.created_by_id).not_to eq(nil)
        expect(link.host_link).to eq(link.host_link)
        expect(link.guest_hearing_link).to eq(link.guest_hearing_link)
        expect(link.guest_pin_long).to eq(link.guest_pin_long)
        expect(link.updated_by_id).not_to eq(nil)
      end
    end

    context "update conference day" do
      let(:hash) do
        {
          host_pin: 12_345_678,
          host_pin_long: "12345678",
          guest_pin_long: "123456789",
          created_at: DateTime.new(2022, 3, 15, 10, 15, 30),
          updated_at: DateTime.new(2022, 4, 27, 11, 20, 35)
        }
      end

      subject { link.update!(hash) }

      it "Conference link was updated" do
        subject

        updated_link = ConferenceLink.find(link.id).reload
        expect(updated_link.host_pin).to eq(123_456_78)
        expect(updated_link.host_pin_long).to eq("12345678")
        expect(updated_link.guest_pin_long).to eq("123456789")
        expect(updated_link.created_at).to eq(DateTime.new(2022, 3, 15, 10, 15, 30))
        expect(updated_link.updated_at).to eq(DateTime.new(2022, 4, 27, 11, 20, 35))
        expect(updated_link.updated_by_id).not_to eq(nil)
        expect(updated_link.created_by_id).not_to eq(nil)
      end
    end
  end
end
