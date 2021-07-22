# frozen_string_literal: true

describe HearingMailer do
  let(:nyc_ro_eastern) { "RO06" }
  let(:oakland_ro_pacific) { "RO43" }
  let(:regional_office) { nyc_ro_eastern }
  let(:hearing_day) do
    create(
      :hearing_day,
      scheduled_for: Date.tomorrow, # This is default, but making it explicit for the tests
      request_type: HearingDay::REQUEST_TYPES[:video],
      regional_office: regional_office
    )
  end

  let(:central_hearing_day) do
    create(
      :hearing_day,
      scheduled_for: Date.tomorrow, # This is default, but making it explicit for the tests
      request_type: HearingDay::REQUEST_TYPES[:central]
    )
  end

  let(:appellant_tz) { nil }
  let(:representative_tz) { nil }
  let(:virtual_hearing) do
    create(
      :virtual_hearing,
      hearing: hearing,
      appellant_tz: appellant_tz,
      representative_tz: representative_tz
    )
  end
  let(:recipient_title) { nil }
  let(:recipient) { MailRecipient.new(name: "LastName", email: "email@test.com", title: recipient_title) }
  let(:pexip_url) { "fake.va.gov" }

  shared_context "ama_hearing" do
    let(:appeal) { create(:appeal, :hearing_docket) }
    let(:hearing) do
      create(
        :hearing,
        appeal: appeal,
        scheduled_time: "8:30AM",
        hearing_day: hearing_day,
        regional_office: regional_office
      )
    end
  end

  shared_context "ama_central_hearing" do
    let(:appeal) { create(:appeal, :hearing_docket) }
    let(:hearing) do
      create(
        :hearing,
        appeal: appeal,
        scheduled_time: "8:30AM",
        hearing_day: central_hearing_day
      )
    end
  end

  shared_context "legacy_base_hearing" do
    let(:correspondent) { create(:correspondent) }
    let(:appellant_address) { nil }
    let(:hearing_date) do
      Time.use_zone("America/New_York") do
        Time.zone.now.change(hour: 11, min: 30) + 1.day # Tomorrow. Matches the AMA hearing scheduled for.
      end
    end
    let(:case_hearing) do
      create(
        :case_hearing,
        hearing_type: legacy_hearing_hearing_day.request_type,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date) # VACOLS always has EST time
      )
    end
    let(:vacols_case) do
      create(
        :case_with_form_9,
        correspondent: correspondent,
        case_issues: [create(:case_issue), create(:case_issue)],
        bfregoff: legacy_hearing_regional_office,
        case_hearings: [case_hearing]
      )
    end
    let(:hearing) do
      create(
        :legacy_hearing,
        case_hearing: case_hearing,
        hearing_day_id: legacy_hearing_hearing_day.id,
        regional_office: legacy_hearing_regional_office,
        appeal: create(
          :legacy_appeal,
          :with_veteran,
          appellant_address: appellant_address,
          closest_regional_office: legacy_hearing_regional_office,
          vacols_case: vacols_case
        )
      )
    end
  end

  shared_context "legacy_hearing" do
    let(:legacy_hearing_hearing_day) { hearing_day }
    let(:legacy_hearing_regional_office) { regional_office }

    include_context "legacy_base_hearing"
  end

  shared_context "legacy_central_hearing" do
    let(:legacy_hearing_hearing_day) { central_hearing_day }
    let(:legacy_hearing_regional_office) { "C" }

    include_context "legacy_base_hearing"
  end

  shared_context "cancellation_email" do
    subject { HearingMailer.cancellation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }
  end

  shared_context "confirmation_email" do
    subject { HearingMailer.confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing) }
  end

  shared_context "updated_time_confirmation_email" do
    subject do
      HearingMailer.updated_time_confirmation(mail_recipient: recipient, virtual_hearing: virtual_hearing)
    end
  end

  shared_context "virtual_reminder_email" do
    subject do
      HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: virtual_hearing)
    end
  end

  shared_context "non_virtual_reminder_email" do
    subject do
      HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: hearing)
    end
  end

  shared_examples "appellant virtual reminder intro" do
    it "displays video hearing reminder email intro" do
      expect(subject.body).to include("You're scheduled for a virtual hearing with a Veterans " \
        "Law Judge of the Board of Veterans' Appeals.")
    end
  end

  shared_examples "appellant video reminder intro" do
    it "displays video hearing reminder email intro" do
      expect(subject.body).to include("You're scheduled for a hearing with a Veterans Law Judge of " \
        "the Board of Veterans' Appeals. You will arrive at #{hearing.location.full_address} and the " \
        "Judge will meet with you via video conference.")
    end
  end

  shared_examples "appellant central reminder intro" do
    it "displays central hearing reminder email intro" do
      expect(subject.body).to include("You're scheduled for a hearing with a Veterans Law Judge of " \
        "the Board of Veterans' Appeals. You will arrive at " \
        "#{hearing.hearing_location_or_regional_office.full_address} and the Judge will meet with you in person")
    end
  end

  shared_examples "representative virtual reminder intro" do
    it "displays virtual hearing reminder email intro" do
      expect(subject.body).to include("You have a client scheduled for a virtual hearing " \
        "with a Veterans Law Judge of the Board of Veterans' Appeals.")
    end
  end

  shared_examples "representative video reminder intro" do
    it "displays central hearing reminder email intro" do
      expect(subject.body).to include("You have a client scheduled for a hearing at a VA Regional " \
        "Office with a Veterans Law Judge of the Board of Veterans' Appeals.")
    end
  end

  shared_examples "representative central reminder intro" do
    it "displays central hearing reminder email intro" do
      expect(subject.body).to include("You have a client scheduled for a hearing at the VA Central" \
        " Office with a Veterans Law Judge of the Board of Veterans' Appeals.")
    end
  end

  shared_examples "representative shared reminder sections" do
    it "displays shared reminder email sections" do
      # Date and Time section
      expect(subject.body).to include("Date and Time")
      expect(subject.body).to include(
        Hearings::CalendarTemplateHelper.format_hearing_time(hearing.time.appellant_time)
      )

      # Signature section
      expect(subject.body).to include("Sincerely,")
      expect(subject.body).to include("The Board of Veterans' Appeals")
    end
  end

  shared_examples "representative non-virtual reminder sections" do
    it "displays non-virtual reminder email sections" do
      # Location section
      expect(subject.body).to include("Location")
      expect(subject.body).to include(hearing.hearing_location_or_regional_office.full_address)
      expect(subject.body).to include(CGI.escapeHTML(hearing.hearing_location_or_regional_office.name))

      # Sections not rendered
      expect(subject.body).not_to include("How to Join")
      expect(subject.body).not_to include("Test Your Connection")
      expect(subject.body).not_to include("Help Desk")
    end
  end

  shared_examples "representative virtual reminder sections" do
    it "displays virtual reminder email sections" do
      # How to Join section
      expect(subject.body).to include("How to Join")

      # Test your Connection section
      expect(subject.body).to include("Test Your Connection")

      # Help Desk section
      expect(subject.body).to include("Help Desk")

      # Internal Use section
      expect(subject.body).to include("For internal Board use:")
      expect(subject.body).to include(hearing.appeal.veteran_state)
      expect(subject.body).to include("<a href=" \
        "\"https://appeals.cf.ds.va.gov/queue/appeals/#{hearing.appeal.external_id}\">CF</a>")

      # Sections not rendered
      expect(subject.body).not_to include("Location")
    end
  end

  shared_examples "appellant shared reminder sections" do
    it "displays shared reminder email sections" do
      # Date and Time section
      expect(subject.body).to include("Date and Time")
      expect(subject.body).to include(
        Hearings::CalendarTemplateHelper.format_hearing_time(hearing.time.appellant_time)
      )

      # Signature section
      expect(subject.body).to include("Sincerely,")
      expect(subject.body).to include("The Board of Veterans' Appeals")

      # Internal Use section
      expect(subject.body).to include("For internal Board use:")
      expect(subject.body).to include(hearing.appeal.veteran_state)
      expect(subject.body).to include("<a href=" \
        "\"https://appeals.cf.ds.va.gov/queue/appeals/#{hearing.appeal.external_id}\">CF</a>")
    end
  end

  shared_examples "appellant non-virtual reminder sections" do
    it "displays non-virtual reminder email sections" do
      # What to expect section
      expect(subject.body).to include("What should I expect on the day of my hearing?")

      # Location section
      expect(subject.body).to include("Location")
      expect(subject.body).to include(hearing.hearing_location_or_regional_office.full_address)
      expect(subject.body).to include(CGI.escapeHTML(hearing.hearing_location_or_regional_office.name))

      # Sections not rendered
      expect(subject.body).not_to include("How to Join")
      expect(subject.body).not_to include("Test Your Connection")
      expect(subject.body).not_to include("Help Desk")
    end
  end

  shared_examples "appellant virtual reminder sections" do
    it "displays virtual reminder email sections" do
      # How to Join section
      expect(subject.body).to include("How to Join")

      # Test your Connection section
      expect(subject.body).to include("Test Your Connection")

      # Help Desk section
      expect(subject.body).to include("Help Desk")

      # Sections not rendered
      expect(subject.body).not_to include("Location")
      expect(subject.body).not_to include("What should I expect on the day of my hearing?")
    end
  end

  before do
    # Freeze the time to when this fix is made to workaround a potential DST bug.
    Timecop.freeze(Time.utc(2020, 1, 20, 16, 50, 0))

    stub_const("ENV", "PEXIP_CLIENT_HOST" => pexip_url)
  end

  context "for judge" do
    let(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:judge] }

    # we expect the judge to always see the hearing time in central office (eastern) time zone

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = {
      ro_and_recipient_both_eastern: "8:30am EST",
      ro_pacific_recipient_eastern: "11:30am EST"
    }
    # legacy hearing is scheduled at 11:30am in the regional office's time zone
    expected_legacy_times = {
      ro_and_recipient_both_eastern: "11:30am EST",
      ro_pacific_recipient_eastern: "2:30pm EST"
    }

    context "with ama hearing" do
      include_context "ama_hearing"

      describe "#cancellation" do
        include_context "cancellation_email"

        it "doesn't send an email" do
          expect { subject.deliver_now! }.to_not(change { ActionMailer::Base.deliveries.count })
        end
      end

      describe "#confirmation" do
        include_context "confirmation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "#link" do
          it "is host link" do
            expect(subject.html_part.body).to include(virtual_hearing.host_link)
          end

          it "is in correct format" do
            expect(virtual_hearing.host_link).to eq(
              "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
              "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
              "pin=#{virtual_hearing.host_pin}&role=host"
            )
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            # judge time in the email will always be in central office time (ET)
            expect(subject.html_part.body).to include(expected_ama_times[:ro_pacific_recipient_eastern])
          end
        end
      end

      describe "#updated_time_confirmation" do
        include_context "updated_time_confirmation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "#link" do
          it "is host link" do
            expect(subject.html_part.body).to include(virtual_hearing.host_link)
          end

          it "is in correct format" do
            expect(virtual_hearing.host_link).to eq(
              "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
              "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
              "pin=#{virtual_hearing.host_pin}&role=host"
            )
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            # judge time in the email will always be in central office time (ET)
            expect(subject.html_part.body).to include(expected_ama_times[:ro_pacific_recipient_eastern])
          end
        end
      end
    end

    context "with legacy hearing" do
      include_context "legacy_hearing"

      describe "#confirmation" do
        include_context "confirmation_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            # judge time in the email will always be in central office time (ET)
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_pacific_recipient_eastern])
          end
        end
      end

      describe "#updated_time_confirmation" do
        include_context "updated_time_confirmation_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            # judge time in the email will always be in central office time (ET)
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_pacific_recipient_eastern])
          end
        end
      end
    end
  end

  context "for appellant" do
    let(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:appellant] }

    # we expect the appellant to always see the hearing time in the regional office time zone
    # unless appellant_tz in VirtualHearing is set

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = {
      ro_and_recipient_both_eastern: "8:30am EST",
      ro_and_recipient_both_pacific: "8:30am PST",
      ro_eastern_recipient_pacific: "5:30am PST"
    }
    # legacy hearing is scheduled at 11:30am in the regional office's time zone
    expected_legacy_times = {
      ro_and_recipient_both_eastern: "11:30am EST",
      ro_and_recipient_both_pacific: "11:30am PST",
      ro_eastern_recipient_pacific: "8:30am PST"
    }

    context "with ama virtual hearing" do
      include_context "ama_hearing"

      describe "#cancellation" do
        include_context "cancellation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "hearing_location is not nil" do
          it "shows correct hearing location" do
            expect(subject.html_part.body).to include(hearing.location.full_address)
            expect(subject.html_part.body).to include(hearing.hearing_location.name)
          end
        end

        describe "hearing_location is nil" do
          it "shows correct hearing location" do
            hearing.update!(hearing_location: nil)
            expect(subject.html_part.body).to include(hearing.regional_office.full_address)
            expect(subject.html_part.body).to include(hearing.regional_office.name)
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "appellant_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#confirmation" do
        include_context "confirmation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "#link" do
          it "has the test link" do
            expect(subject.html_part.body).to include(virtual_hearing.test_link(recipient_title))
          end

          it "is guest link" do
            expect(subject.html_part.body).to include(virtual_hearing.guest_link)
          end

          it "is in correct format" do
            expect(virtual_hearing.guest_link).to eq(
              "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
              "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
              "pin=#{virtual_hearing.guest_pin}&role=guest"
            )
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "appellant_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        describe "internal use section" do
          it "has veteran's state of residence" do
            # FL is the default veteran's state of residence
            expect(subject.html_part.body.decoded).to include("For internal Board use:\r\n  FL")
          end

          context "veteran is not appellant" do
            let(:appeal) do
              create(
                :appeal,
                :hearing_docket,
                number_of_claimants: 1,
                veteran_is_not_claimant: true
              )
            end

            it "has appellant's state of residence" do
              # CA is the default appellant's state of residence
              expect(subject.html_part.body.decoded).to include("For internal Board use:\r\n  CA")
            end
          end
        end
      end

      describe "#updated_time_confirmation" do
        include_context "updated_time_confirmation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "#link" do
          it "has the test link" do
            expect(subject.html_part.body).to include(virtual_hearing.test_link(recipient_title))
          end

          it "is guest link" do
            expect(subject.html_part.body).to include(virtual_hearing.guest_link)
          end

          it "is in correct format" do
            expect(virtual_hearing.guest_link).to eq(
              "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
              "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
              "pin=#{virtual_hearing.guest_pin}&role=guest"
            )
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "appellant_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#reminder" do
        include_context "virtual_reminder_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_ama_times[:ro_and_recipient_both_eastern]} – Do Not Reply"
            )
          end
        end

        context "regional office is in western timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_ama_times[:ro_and_recipient_both_pacific]} – Do Not Reply"
            )
          end
        end

        context "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_ama_times[:ro_eastern_recipient_pacific]} – Do Not Reply"
            )
          end
        end

        context "appellant_tz is not present" do
          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_ama_times[:ro_and_recipient_both_eastern]} – Do Not Reply"
            )
          end
        end

        context "email body" do
          include_examples "appellant virtual reminder intro"
          include_examples "appellant shared reminder sections"
          include_examples "appellant virtual reminder sections"
        end
      end
    end

    context "with ama video hearing" do
      include_context "ama_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "appellant video reminder intro"
          include_examples "appellant shared reminder sections"
          include_examples "appellant non-virtual reminder sections"
        end
      end
    end

    context "with ama central hearing" do
      include_context "ama_central_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "appellant central reminder intro"
          include_examples "appellant shared reminder sections"
          include_examples "appellant non-virtual reminder sections"
        end
      end
    end

    context "with legacy virtual hearing" do
      include_context "legacy_hearing"

      describe "#cancellation" do
        include_context "cancellation_email"

        describe "hearing_location is not nil" do
          it "shows correct hearing location" do
            expect(subject.html_part.body).to include(hearing.location.full_address)
            expect(subject.html_part.body).to include(hearing.hearing_location.name)
          end
        end

        describe "hearing_location is nil" do
          it "shows correct hearing location" do
            hearing.update!(hearing_location: nil)
            expect(subject.html_part.body).to include(hearing.regional_office.full_address)
            expect(subject.html_part.body).to include(hearing.regional_office.name)
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "appellant_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#confirmation" do
        include_context "confirmation_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "appellant_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        describe "internal use section" do
          it "has veteran's state of residence" do
            # FL is the default veteran's state of residence
            expect(subject.html_part.body.decoded).to include("For internal Board use:\r\n  FL")
          end

          context "veteran is not appellant" do
            let(:correspondent) do
              create(
                :correspondent,
                appellant_first_name: "Sirref",
                appellant_last_name: "Test",
                ssn: "333224444"
              )
            end
            let(:appellant_address) do
              {
                addrs_one_txt: "9001 FAKE ST",
                addrs_two_txt: "APT 2",
                addrs_three_txt: nil,
                city_nm: "BROOKLYN",
                postal_cd: "NY",
                cntry_nm: nil,
                zip_prefix_nbr: "11222"
              }
            end

            it "has appellant's state of residence" do
              expect(subject.html_part.body.decoded).to include("For internal Board use:\r\n  NY")
            end
          end
        end
      end

      describe "#updated_time_confirmation" do
        include_context "updated_time_confirmation_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "appellant_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#reminder" do
        include_context "virtual_reminder_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_legacy_times[:ro_and_recipient_both_eastern]} – Do Not Reply"
            )
          end
        end

        context "regional office is in western timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_legacy_times[:ro_and_recipient_both_pacific]} – Do Not Reply"
            )
          end
        end

        context "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_legacy_times[:ro_eastern_recipient_pacific]} – Do Not Reply"
            )
          end
        end

        context "appellant_tz is not present" do
          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at " \
              "#{expected_legacy_times[:ro_and_recipient_both_eastern]} – Do Not Reply"
            )
          end
        end
      end
    end

    context "with legacy video hearing" do
      include_context "legacy_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "appellant video reminder intro"
          include_examples "appellant shared reminder sections"
          include_examples "appellant non-virtual reminder sections"
        end
      end
    end

    context "with legacy central hearing" do
      include_context "legacy_central_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "appellant central reminder intro"
          include_examples "appellant shared reminder sections"
          include_examples "appellant non-virtual reminder sections"
        end
      end
    end
  end

  context "for representative" do
    let(:recipient_title) { MailRecipient::RECIPIENT_TITLES[:representative] }

    # we expect the representative to always see the hearing time in the regional office time zone
    # unless representative_tz in VirtualHearing is set

    # ama hearing is scheduled at 8:30am in the regional office's time zone
    expected_ama_times = {
      ro_and_recipient_both_eastern: "8:30am EST",
      ro_and_recipient_both_pacific: "8:30am PST",
      ro_eastern_recipient_pacific: "5:30am PST"
    }
    # legacy hearing is scheduled at 11:30am in the regional office's time zone
    expected_legacy_times = {
      ro_and_recipient_both_eastern: "11:30am EST",
      ro_and_recipient_both_pacific: "11:30am PST",
      ro_eastern_recipient_pacific: "8:30am PST"
    }

    context "with ama virtual hearing" do
      include_context "ama_hearing"

      describe "#cancellation" do
        include_context "cancellation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "hearing_location is not nil" do
          it "shows correct hearing location" do
            expect(subject.html_part.body).to include(hearing.location.full_address)
            expect(subject.html_part.body).to include(hearing.hearing_location.name)
          end
        end

        describe "hearing_location is nil" do
          it "shows correct hearing location" do
            hearing.update!(hearing_location: nil)
            expect(subject.html_part.body).to include(hearing.regional_office.full_address)
            expect(subject.html_part.body).to include(hearing.regional_office.name)
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "representative_tz is present" do
          let(:representative_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "representative_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#confirmation" do
        include_context "confirmation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "#link" do
          it "has the test link" do
            expect(subject.html_part.body).to include(virtual_hearing.test_link(recipient_title))
          end

          it "is guest link" do
            expect(subject.html_part.body).to include(virtual_hearing.guest_link)
          end

          it "is in correct format" do
            expect(virtual_hearing.guest_link).to eq(
              "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
              "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
              "pin=#{virtual_hearing.guest_pin}&role=guest"
            )
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "representative_tz is present" do
          let(:representative_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "representative_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#updated_time_confirmation" do
        include_context "updated_time_confirmation_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        describe "#link" do
          it "has the test link" do
            expect(subject.html_part.body).to include(virtual_hearing.test_link(recipient_title))
          end

          it "is guest link" do
            expect(subject.html_part.body).to include(virtual_hearing.guest_link)
          end

          it "is in correct format" do
            expect(virtual_hearing.guest_link).to eq(
              "#{VirtualHearing.base_url}?join=1&media=&escalate=1&" \
              "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&" \
              "pin=#{virtual_hearing.guest_pin}&role=guest"
            )
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "representative_tz is present" do
          let(:representative_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "representative_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_ama_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#reminder" do
        include_context "virtual_reminder_email"
        # Concatentated for each test to look like the reminder_subject in hearing_mailer.rb
        let(:first_clause) { "Reminder: #{appeal.appellant_or_veteran_name}'s Board hearing is Tue, Jan 21 at" }
        let(:do_not_reply_clause) { "– Do Not Reply" }

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_ama_times[:ro_and_recipient_both_eastern]} #{do_not_reply_clause}"
            )
          end
        end

        context "regional office is in western timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_ama_times[:ro_and_recipient_both_pacific]} #{do_not_reply_clause}"
            )
          end
        end

        context "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_ama_times[:ro_eastern_recipient_pacific]} #{do_not_reply_clause}"
            )
          end
        end

        context "appellant_tz is not present" do
          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_ama_times[:ro_and_recipient_both_eastern]} #{do_not_reply_clause}"
            )
          end
        end

        context "email body" do
          include_examples "representative virtual reminder intro"
          include_examples "representative shared reminder sections"
          include_examples "representative virtual reminder sections"
        end
      end
    end

    context "with ama video hearing" do
      include_context "ama_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "representative video reminder intro"
          include_examples "representative shared reminder sections"
          include_examples "representative non-virtual reminder sections"
        end
      end
    end

    context "with ama central hearing" do
      include_context "ama_central_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "representative central reminder intro"
          include_examples "representative shared reminder sections"
          include_examples "representative non-virtual reminder sections"
        end
      end
    end

    context "with legacy virtual hearing" do
      include_context "legacy_hearing"

      describe "#cancellation" do
        include_context "cancellation_email"

        describe "hearing_location is not nil" do
          it "shows correct hearing location" do
            expect(subject.html_part.body).to include(hearing.location.full_address)
            expect(subject.html_part.body).to include(hearing.hearing_location.name)
          end
        end

        describe "hearing_location is nil" do
          it "shows correct hearing location" do
            hearing.update!(hearing_location: nil)
            expect(subject.html_part.body).to include(hearing.regional_office.full_address)
            expect(subject.html_part.body).to include(hearing.regional_office.name)
          end
        end

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "representative_tz is present" do
          let(:representative_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "representative_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#confirmation" do
        include_context "confirmation_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "representative_tz is present" do
          let(:representative_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "representative_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#updated_time_confirmation" do
        include_context "updated_time_confirmation_email"

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end

        context "regional office is in pacific timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct time in the email" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_pacific])
          end
        end

        describe "representative_tz is present" do
          let(:representative_tz) { "America/Los_Angeles" }

          it "displays pacific standard time (PT)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_eastern_recipient_pacific])
          end
        end

        describe "representative_tz is not present" do
          it "displays eastern standard time (ET)" do
            expect(subject.html_part.body).to include(expected_legacy_times[:ro_and_recipient_both_eastern])
          end
        end
      end

      describe "#reminder" do
        include_context "virtual_reminder_email"
        # Concatentated for each test to look like the reminder_subject in hearing_mailer.rb
        let(:name) { virtual_hearing.hearing.appeal.appellant_or_veteran_name }
        let(:first_clause) { "Reminder: #{name}'s Board hearing is Tue, Jan 21 at" }
        let(:do_not_reply_clause) { "– Do Not Reply" }

        context "regional office is in eastern timezone" do
          let(:regional_office) { nyc_ro_eastern }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_legacy_times[:ro_and_recipient_both_eastern]} #{do_not_reply_clause}"
            )
          end
        end

        context "regional office is in western timezone" do
          let(:regional_office) { oakland_ro_pacific }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_legacy_times[:ro_and_recipient_both_pacific]} #{do_not_reply_clause}"
            )
          end
        end

        context "appellant_tz is present" do
          let(:appellant_tz) { "America/Los_Angeles" }

          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_legacy_times[:ro_eastern_recipient_pacific]} #{do_not_reply_clause}"
            )
          end
        end

        context "appellant_tz is not present" do
          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "#{first_clause} #{expected_legacy_times[:ro_and_recipient_both_eastern]} #{do_not_reply_clause}"
            )
          end
        end

        context "email body" do
          include_examples "representative virtual reminder intro"
          include_examples "representative shared reminder sections"
          include_examples "representative virtual reminder sections"
        end
      end
    end

    context "with legacy video hearing" do
      include_context "legacy_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "representative video reminder intro"
          include_examples "representative shared reminder sections"
          include_examples "representative non-virtual reminder sections"
        end
      end
    end

    context "with legacy central hearing" do
      include_context "legacy_central_hearing"

      describe "#reminder" do
        include_context "non_virtual_reminder_email"

        it "sends an email" do
          expect { subject.deliver_now! }.to change { ActionMailer::Base.deliveries.count }.by 1
        end

        context "email body" do
          include_examples "representative central reminder intro"
          include_examples "representative shared reminder sections"
          include_examples "representative non-virtual reminder sections"
        end
      end
    end
  end
end
