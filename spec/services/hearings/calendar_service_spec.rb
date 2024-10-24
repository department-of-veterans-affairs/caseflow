# frozen_string_literal: true

describe Hearings::CalendarService do
  describe ".confirmation_calendar_invite" do
    subject(:confirmation_calendar_invite) do
      described_class.confirmation_calendar_invite(virtual_hearing, email_recipient_info, link)
    end

    let(:regional_office) { "RO06" } # nyc_ro_eastern
    let(:appeal) { create(:appeal, :hearing_docket) }
    let(:hearing_day) do
      create(:hearing_day, scheduled_for: Date.parse("January 1, 1970"),
                           request_type: HearingDay::REQUEST_TYPES[:video],
                           regional_office: regional_office)
    end
    let(:hearing) do
      create(:hearing, appeal: appeal,
                       scheduled_time: "8:30AM",
                       hearing_day: hearing_day,
                       regional_office: regional_office)
    end
    let(:virtual_hearing) do
      create(:virtual_hearing, hearing: hearing, appellant_tz: nil, representative_tz: nil)
    end
    let(:email_recipient_info) do
      EmailRecipientInfo.new(name: "LastName",
                             title: "appellant",
                             hearing_email_recipient: hearing_email_recipient)
    end
    let(:hearing_email_recipient) { virtual_hearing.hearing.appellant_recipient }
    let(:link) { virtual_hearing.guest_link }

    context "With an Eastern Time hearing" do
      it "returns appropriate iCalendar event" do
        expected_description = <<~TEXT
          You're scheduled for a virtual hearing with a Veterans Law Judge of the Board of Veterans' Appeals.

          Date and Time
          Thursday, 1 January 1970 at 8:30am EST

          How to Join
          We recommend joining 15 minutes before your hearing start time. Click on the link below, or copy and paste the link into the address field of your web browser:
          https://care.evn.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA@care.evn.va.gov&pin=&role=guest

          Help Desk
          If you are experiencing technical difficulties, call the VA Video Connect Helpdesk at 855-519-7116 and press 4 for Board of Veterans' Appeals support.

          Rescheduling or Canceling Your Hearing
          If you need to reschedule or cancel your virtual hearing, contact us by email at bvahearingteamhotline@va.gov
        TEXT

        aggregate_failures do
          expect(confirmation_calendar_invite).to be_a(String)

          ical_event = Icalendar::Calendar.parse(confirmation_calendar_invite).first.events.first

          expect(ical_event.url.to_s).to eq(
            "https://care.evn.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA@care.evn.va.gov&pin=&role=guest"
          )
          expect(ical_event.location).to eq(
            "https://care.evn.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA@care.evn.va.gov&pin=&role=guest"
          )
          expect(ical_event.status).to eq("CONFIRMED")
          expect(ical_event.summary).to be_nil
          expect(ical_event.description).to eq(expected_description)
        end
      end
    end

    context "With a Boise RO hearing" do
      let(:regional_office) { "RO47" }

      it "Displays correct time" do
        ical_event = Icalendar::Calendar.parse(confirmation_calendar_invite).first.events.first

        expect(ical_event.dtstart.to_s).to eq "1970-01-01 08:30:00 -0700"
      end
    end
  end
end
