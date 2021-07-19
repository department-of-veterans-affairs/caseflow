# frozen_string_literal: true

RSpec.feature "Editing Virtual Hearings from Hearing Details" do
  def check_row_content(event, index)
    # Format the date the same as moment
    formatted_date = event.sent_at.strftime("%b %d, %Y, %-l:%M %P %Z").gsub(/DT/, "ST")

    expect(find("#table-row-#{index} > td:first-child")).to have_content(event.sent_to_role)
    expect(find("#table-row-#{index} > td:nth-child(2)")).to have_content(event.email_address)
    expect(find("#table-row-#{index} > td:nth-child(3)")).to have_content(formatted_date)
    expect(find("#table-row-#{index} > td:last-child")).to have_content(event.sent_by.username)
  end

  def check_email_event_rows(hearing, row_count)
    within "#virtualHearingEmailEvents table > tbody" do
      # Expecting 2 because rep email is filled as well
      expect(find_all("tr").length).to eq(row_count)

      hearing.email_events.order(sent_at: :desc).map.with_index do |event, index|
        check_row_content(event, index)
      end
    end
  end

  def check_email_event_headers
    expect(page).to have_selector("#virtualHearingEmailEvents")

    within "#virtualHearingEmailEvents table > thead > tr" do
      expect(find("th:first-child")).to have_content("Sent To")
      expect(find("th:nth-child(2)")).to have_content("Email Address")
      expect(find("th:nth-child(3)")).to have_content("Date Sent")
      expect(find("th:last-child")).to have_content("Sent By")
    end
  end

  def check_email_event_table(hearing, row_count)
    check_email_event_headers
    check_email_event_rows(hearing, row_count)
  end

  let(:current_user) do
    create(
      :user,
      :judge,
      css_id: "BVATWARNER",
      roles: ["Build HearSched"],
      email: "test@gmail.com"
    )
  end

  let(:fill_in_veteran_email) { "new@email.com" }
  let(:fill_in_veteran_tz) { "America/New_York" }

  let(:fill_in_rep_email) { "rep@testingEmail.com" }
  let(:fill_in_rep_tz) { "America/Chicago" }

  let(:pexip_url) { "fake.va.gov" }

  before do
    create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG")
    create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO")
    HearingsManagement.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
    FeatureToggle.enable!(:schedule_virtual_hearings)
    FeatureToggle.enable!(:full_page_video_to_virtual)
    FeatureToggle.enable!(:schedule_virtual_hearings_for_central)
    stub_const("ENV", "PEXIP_CLIENT_HOST" => pexip_url)
  end

  let!(:expected_alert) do
    COPY::VIRTUAL_HEARING_SUCCESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
  end

  let(:pre_loaded_veteran_email) { hearing.appeal.veteran.email_address }
  let(:pre_loaded_rep_email) { hearing.appeal.representative_email_address }
  let(:fill_in_veteran_email) { "email@testingEmail.com" }

  def check_virtual_hearings_links_expired(virtual_hearing)
    within "#vlj-hearings-link" do
      expect(page).to have_content(
        "VLJ Link: Expired\n" \
        "Conference Room: #{virtual_hearing.formatted_alias_or_alias_with_host}\n" \
        "PIN: #{virtual_hearing.host_pin}"
      )
    end
    within "#guest-hearings-link" do
      expect(page).to have_content(
        "Guest Link: Expired\n" \
        "Conference Room: #{virtual_hearing.formatted_alias_or_alias_with_host}\n" \
        "PIN: #{virtual_hearing.guest_pin}"
      )
    end
  end

  def check_virtual_hearings_links(virtual_hearing, disable_link = false)
    # Test the hearing link details
    within "#vlj-hearings-link" do
      expect(page).to have_content(
        "VLJ Link: Start Virtual Hearing \n" \
        "Conference Room: #{virtual_hearing.formatted_alias_or_alias_with_host}\n" \
        "PIN: #{virtual_hearing.host_pin}\n" \
        "Copy VLJ Link "
      )

      ensure_link_present(virtual_hearing.host_link, disable_link)
    end
    within "#guest-hearings-link" do
      expect(page).to have_content(
        "Guest Link: Join Virtual Hearing \n" \
        "Conference Room: #{virtual_hearing.formatted_alias_or_alias_with_host}\n" \
        "PIN: #{virtual_hearing.guest_pin}\n" \
        "Copy Guest Link "
      )

      ensure_link_present(virtual_hearing.guest_link, disable_link)
    end
  end

  def ensure_link_present(link, disable)
    expect(page).to have_selector(:css, "a[href='#{link}']") unless disable
  end

  shared_examples "shared behaviors" do
    context "Before hearing type is converted" do
      scenario "email notification history is not displayed" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        # Email notifications should not be displayed when the initial request is Video
        expect(page).not_to have_selector("#virtualHearingEmailEvents")
        expect(page).not_to have_css("#virtualHearingEmailEvents table")
      end
    end

    context "User switches hearing type to Virtual" do
      it "switching type to Virtual is successful" do
        step "veteran and representative emails are pre loaded" do
          visit "hearings/" + hearing.external_id.to_s + "/details"
          click_dropdown(name: "hearingType", index: 0)
          expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

          expect(page).to have_field("Veteran Email", with: pre_loaded_veteran_email)
          expect(page).to have_field("POA/Representative Email", with: pre_loaded_rep_email)
        end

        step "fill in form and switch to `Virtual`" do
          fill_in "Veteran Email", with: fill_in_veteran_email
          click_button(COPY::CONVERT_HEARING_TITLE % "Virtual")

          expect(page).to have_content(expected_alert)

          hearing.reload
          expect(VirtualHearing.count).to eq(1)
          expect(hearing.virtual?).to eq(true)
          expect(hearing.virtual_hearing.appellant_email).to eq("email@testingEmail.com")
          expect(hearing.virtual_hearing.representative_email).to eq(pre_loaded_rep_email)
          expect(hearing.virtual_hearing.judge_email).to eq(nil)
        end

        step "email notification history displays correctly" do
          # check for SentHearingEmailEvents
          events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
          expect(events.count).to eq 2
          expect(events.where(sent_by_id: current_user.id).count).to eq 2
          expect(events.where(email_type: "confirmation").count).to eq 2
          expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
          expect(events.sent_to_appellant.count).to eq 1
          expect(events.where(email_address: pre_loaded_rep_email).count).to eq 1
          expect(events.where(recipient_role: "representative").count).to eq 1

          # Check the Email Notification History
          check_email_event_table(hearing, 2)
        end
      end

      scenario "for hearings with a VLJ, displays email notifications for sent emails events" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        # Attach a VLJ to the hearing so they will get an email
        hearing.update(judge: current_user)

        # Change the hearing type to virtual
        click_dropdown(name: "hearingType", index: 0)
        expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

        # Fill email address and confirm changes to close the Modal
        fill_in "Veteran Email", with: fill_in_veteran_email
        click_button(COPY::CONVERT_HEARING_TITLE % "Virtual")
        expect(page).to have_content(expected_alert)

        # Reload the hearing to get the page updates
        hearing.reload

        # Check the Email Notification History
        check_email_event_table(hearing, 3)
      end
    end

    context "User switches hearing type from Virtual back to original type" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :initialized,
          :all_emails_sent,
          :timezones_initialized,
          status: :active,
          appellant_email: fill_in_veteran_email,
          hearing: hearing
        )
      end

      # Mock an Email Event for the Veteran
      let!(:veteran_email_event) do
        create(
          :sent_hearing_email_event,
          email_address: fill_in_veteran_email,
          sent_by: current_user,
          hearing: hearing
        )
      end

      # Mock an Email Event for the Rep
      let!(:rep_email_event) do
        create(
          :sent_hearing_email_event,
          email_address: pre_loaded_rep_email,
          sent_by: current_user,
          hearing: hearing
        )
      end

      let!(:expected_alert) do
        COPY::VIRTUAL_HEARING_SUCCESS_ALERTS["CHANGED_FROM_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
      end

      scenario "email notifications and links display correctly" do
        visit "hearings/" + hearing.external_id.to_s + "/details"
        click_dropdown(name: "hearingType", index: 0)

        # Confirm the Modal change to cancel the virtual hearing
        click_button(COPY::CONVERT_HEARING_TITLE % hearing.readable_request_type)

        expect(page).to have_content(expected_alert)

        # Reload to get the updated page contents
        hearing.reload

        virtual_hearing.reload
        expect(virtual_hearing.cancelled?).to eq(true)
        expect(page).to have_content(hearing.readable_request_type)

        # Check the Email Notification History
        check_email_event_table(hearing, 4)

        # Check that links were generated correctly
        check_virtual_hearings_links_expired(virtual_hearing)
      end
    end

    context "Links display correctly when scheduling Virtual Hearings" do
      let!(:virtual_hearing) { create(:virtual_hearing, :all_emails_sent, hearing: hearing) }

      scenario "displays in progress when the virtual hearing is being scheduled" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        # Test the links are not present
        within "#vlj-hearings-link" do
          expect(page).to have_content("Scheduling in progress")
        end
        within "#guest-hearings-link" do
          expect(page).to have_content("Scheduling in progress")
        end
      end

      context "after the virtual hearing is scheduled" do
        let!(:hearing_day) { create(:hearing_day, scheduled_for: Date.yesterday - 2) }
        before do
          # Mock the conference details
          virtual_hearing.alias_name = rand(1..9).to_s[0..6]
          virtual_hearing.generate_conference_pins
          virtual_hearing.conference_id = "0"
          virtual_hearing.established!
          hearing.reload
        end

        scenario "displays details when the date is before the hearing date" do
          visit "hearings/" + hearing.external_id.to_s + "/details"
          check_virtual_hearings_links(virtual_hearing)
        end

        scenario "displays expired when the date is after the hearing date" do
          hearing.update(hearing_day: hearing_day)
          visit "hearings/" + hearing.external_id.to_s + "/details"
          hearing.reload
          check_virtual_hearings_links_expired(virtual_hearing)
        end

        scenario "displays expired when the virtual hearing is cancelled" do
          virtual_hearing.update(request_cancelled: true)
          visit "hearings/" + hearing.external_id.to_s + "/details"
          hearing.reload
          check_virtual_hearings_links_expired(virtual_hearing)
        end

        scenario "displays disabled virtual hearing link when changing emails" do
          virtual_hearing.update(
            appellant_email_sent: false,
            representative_email_sent: false,
            judge_email_sent: false
          )
          visit "hearings/" + hearing.external_id.to_s + "/details"
          hearing.reload
          check_virtual_hearings_links(virtual_hearing, true)
        end
      end
    end

    context "Hearing type dropdown and vet and poa fields are disabled while async job is running" do
      let!(:virtual_hearing) { create(:virtual_hearing, :all_emails_sent, hearing: hearing) }

      scenario "async job is not completed" do
        visit "hearings/" + hearing.external_id.to_s + "/details"
        expect(find(".dropdown-hearingType")).to have_css(".cf-select__control--is-disabled")
        expect(page).to have_field("Veteran Email", readonly: true)
        expect(page).to have_field("POA/Representative Email", readonly: true)
      end

      scenario "async job is completed" do
        # Mock the conference details
        virtual_hearing.alias_name = rand(1..9).to_s[0..6]
        virtual_hearing.guest_pin = rand(1..9).to_s[0..3].to_i
        virtual_hearing.host_pin = rand(1..9).to_s[0..3].to_i
        virtual_hearing.conference_id = "0"

        virtual_hearing.established!
        visit "hearings/" + hearing.external_id.to_s + "/details"
        hearing.reload
        expect(find(".dropdown-hearingType")).to have_no_css(".cf-select__control--is-disabled")
        expect(page).to have_field("Veteran Email", readonly: false)
        expect(page).to have_field("POA/Representative Email", readonly: false)
      end
    end

    context "User can see and edit veteran and poa emails" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :all_emails_sent,
          :timezones_initialized,
          status: :active,
          hearing: hearing
        )
      end
      let(:fill_in_veteran_email) { "new@email.com" }
      let(:fill_in_rep_email) { "rep@testingEmail.com" }

      scenario "user can update emails" do
        visit "hearings/" + hearing.external_id.to_s + "/details"
        fill_in "Veteran Email", with: fill_in_veteran_email
        fill_in "POA/Representative Email", with: fill_in_rep_email
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("Veteran Email", with: fill_in_veteran_email)
        expect(page).to have_field("POA/Representative Email", with: fill_in_rep_email)

        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 2
        expect(events.where(sent_by_id: current_user.id).count).to eq 2
        expect(events.where(email_type: "confirmation").count).to eq 2
        expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1
        expect(events.where(email_address: fill_in_rep_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 2)
      end

      scenario "input empty veteran email and valid representative email shows validation error" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "Veteran Email", with: ""
        fill_in "POA/Representative Email", with: fill_in_rep_email
        click_button("Save")

        expect(page).to have_content("Veteran email is required")
      end
    end

    context "User can see disabled email fields after switching hearing back to video" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :initialized,
          :all_emails_sent,
          status: :cancelled,
          hearing: hearing
        )
      end

      scenario "email fields are visible but disabled" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("Veteran Email", readonly: true)
        expect(page).to have_field("POA/Representative Email", readonly: true)
      end
    end

    context "Updating POA/Representative email address" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :all_emails_sent,
          :timezones_initialized,
          status: :active,
          hearing: hearing
        )
      end

      scenario "Sends confirmation email only to the POA/Representative" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "POA/Representative Email", with: fill_in_rep_email
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("POA/Representative Email", with: fill_in_rep_email)

        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 1
        expect(events.where(sent_by_id: current_user.id).count).to eq 1
        expect(events.where(email_type: "confirmation").count).to eq 1
        expect(events.where(email_address: fill_in_rep_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 1)
      end

      scenario "Removing POA/Representative email address gives expected alert" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "POA/Representative Email", with: ""
        click_button("Save")

        expect(page.has_no_content?(COPY::VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE)).to be(true)
        expect(page).to have_content(COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name)
      end

      scenario "Entering invalid representative email and shows validation error" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "POA/Representative Email", with: "123456"
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        expect(page).to have_content("Representative email does not appear to be a valid e-mail address")
      end
    end

    context "Updating Appellant email address" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :all_emails_sent,
          :timezones_initialized,
          status: :active,
          hearing: hearing
        )
      end

      scenario "Sends confirmation email only to the Appellant" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "Veteran Email", with: fill_in_veteran_email
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_EMAIL_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("Veteran Email", with: fill_in_veteran_email)

        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 1
        expect(events.where(sent_by_id: current_user.id).count).to eq 1
        expect(events.where(email_type: "confirmation").count).to eq 1
        expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 1)
      end
    end

    context "Updating POA/Representative timezone" do
      let!(:virtual_hearing) do
        create(:virtual_hearing,
               :all_emails_sent,
               :timezones_initialized,
               status: :active,
               hearing: hearing)
      end

      scenario "Sends update hearing time email only to the POA/Representative" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        click_dropdown(name: "representativeTz", index: 1)
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_TIMEZONE_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("representative-tz")
        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 1
        expect(events.where(sent_by_id: current_user.id).count).to eq 1
        expect(events.where(email_type: "updated_time_confirmation").count).to eq 1
        expect(events.where(email_address: virtual_hearing.representative_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 1)
      end
    end

    context "Updating Appellant timezone" do
      let!(:virtual_hearing) do
        create(:virtual_hearing,
               :all_emails_sent,
               :timezones_initialized,
               status: :active,
               hearing: hearing)
      end

      scenario "Sends update hearing time email only to the Appellant" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        click_dropdown(name: "appellantTz", index: 1)
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_TIMEZONE_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("appellant-tz")

        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 1
        expect(events.where(sent_by_id: current_user.id).count).to eq 1
        expect(events.where(email_type: "updated_time_confirmation").count).to eq 1
        expect(events.where(email_address: virtual_hearing.appellant_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 1)
      end
    end

    context "Updating both Appellant and POA/Representative timezone" do
      let!(:virtual_hearing) do
        create(:virtual_hearing,
               :all_emails_sent,
               :timezones_initialized,
               status: :active,
               hearing: hearing)
      end

      scenario "Sends update hearing time emails to both the Appellant and the POA/Representative" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        click_dropdown(name: "representativeTz", index: 1)
        click_dropdown(name: "appellantTz", index: 1)
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_TIMEZONE_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("appellant-tz")

        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 2
        expect(events.where(sent_by_id: current_user.id).count).to eq 2
        expect(events.where(email_type: "updated_time_confirmation").count).to eq 2
        expect(events.where(email_address: virtual_hearing.appellant_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1
        expect(events.where(email_address: virtual_hearing.representative_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 2)
      end
    end

    context "Updating either Appellant and POA/Representative email address and timezone" do
      let!(:virtual_hearing) do
        create(:virtual_hearing,
               :all_emails_sent,
               :timezones_initialized,
               status: :active,
               hearing: hearing)
      end

      scenario "Sends the confirmation email" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "POA/Representative Email", with: fill_in_rep_email
        click_dropdown(name: "appellantTz", index: 1)
        click_button("Save")

        expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_UPDATE_GENERIC_TITLE)
        expect(page).to have_content(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)
        click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON)

        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_field("appellant-tz")

        events = CaseflowRecord::SentHearingEmailEvent.where(hearing_id: hearing.id)
        expect(events.count).to eq 2
        expect(events.where(sent_by_id: current_user.id).count).to eq 2
        expect(events.where(email_type: "confirmation").count).to eq 2
        expect(events.where(email_address: virtual_hearing.appellant_email).count).to eq 1
        expect(events.sent_to_appellant.count).to eq 1
        expect(events.where(email_address: fill_in_rep_email).count).to eq 1
        expect(events.where(recipient_role: "representative").count).to eq 1

        # Check the Email Notification History
        check_email_event_table(hearing, 2)
      end
    end
  end

  context "Initally a Video hearing" do
    let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO13") }

    include_examples "shared behaviors"
  end

  context "Initally a Central hearing " do
    let!(:hearing) { create(:hearing, :with_tasks) }

    include_examples "shared behaviors"
  end
end
