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
      request_type: HearingDay::REQUEST_TYPES[:central],
      regional_office: "C"
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

  shared_context "legacy_hearing" do
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
        hearing_type: hearing_day.request_type,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date) # VACOLS always has EST time
      )
    end
    let(:vacols_case) do
      create(
        :case_with_form_9,
        correspondent: correspondent,
        case_issues: [create(:case_issue), create(:case_issue)],
        bfregoff: regional_office,
        case_hearings: [case_hearing]
      )
    end
    let(:hearing) do
      create(
        :legacy_hearing,
        case_hearing: case_hearing,
        hearing_day_id: hearing_day.id,
        regional_office: regional_office,
        appeal: create(
          :legacy_appeal,
          :with_veteran,
          appellant_address: appellant_address,
          closest_regional_office: regional_office,
          vacols_case: vacols_case
        )
      )
    end
  end

  shared_context "legacy_central_hearing" do
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
        hearing_type: central_hearing_day.request_type,
        hearing_date: VacolsHelper.format_datetime_with_utc_timezone(hearing_date) # VACOLS always has EST time
      )
    end
    let(:vacols_case) do
      create(
        :case_with_form_9,
        correspondent: correspondent,
        case_issues: [create(:case_issue), create(:case_issue)],
        bfregoff: "C",
        case_hearings: [case_hearing]
      )
    end
    let(:hearing) do
      create(
        :legacy_hearing,
        case_hearing: case_hearing,
        hearing_day_id: central_hearing_day.id,
        regional_office: "C",
        appeal: create(
          :legacy_appeal,
          :with_veteran,
          appellant_address: appellant_address,
          closest_regional_office: "C",
          vacols_case: vacols_case
        )
      )
    end
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

  shared_context "video_reminder_email" do
    subject do
      HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: virtual_hearing)
    end
  end

  shared_context "central_reminder_email" do
    subject do
      HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: ama_hearing)
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
      end
    end

    context "with ama video hearing" do
      include_context "ama_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: ama_hearing)
        end
      end
    end

    context "with ama central hearing" do
      include_context "ama_central_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: ama_central_hearing)
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
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: legacy_hearing)
        end
      end
    end

    context "with legacy central hearing" do
      include_context "legacy_central_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: legacy_central_hearing)
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
      end
    end

    context "with ama video hearing" do
      include_context "ama_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: ama_hearing)
        end
      end
    end

    context "with ama central hearing" do
      include_context "ama_central_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: ama_central_hearing)
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
              "Reminder: Your Board hearing is Tue, Jan 21 at "\
              "#{expected_legacy_times[:ro_eastern_recipient_pacific]} – Do Not Reply"
            )
          end
        end

        context "appellant_tz is not present" do
          it "has the correct subject line" do
            expect(subject.subject).to eq(
              "Reminder: Your Board hearing is Tue, Jan 21 at "\
              "#{expected_legacy_times[:ro_and_recipient_both_eastern]} – Do Not Reply"
            )
          end
        end
      end
    end

    context "with legacy video hearing" do
      include_context "legacy_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: legacy_hearing)
        end
      end
    end

    context "with legacy central hearing" do
      include_context "legacy_central_hearing"

      describe "#reminder" do
        subject do
          HearingMailer.reminder(mail_recipient: recipient, virtual_hearing: nil, hearing: legacy_central_hearing)
        end
      end
    end
  end
end
