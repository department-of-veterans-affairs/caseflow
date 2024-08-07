# frozen_string_literal: true

RSpec.feature "Hearing Details", :all_dbs do
  before do
    # VSO users require this task to be active on an appeal for them to access its hearings.
    TrackVeteranTask.create!(appeal: hearing.appeal, parent: hearing.appeal.root_task, assigned_to: vso_org)
    allow_any_instance_of(User).to receive(:vsos_user_represents).and_return(
      [{ participant_id: vso_participant_id }]
    )

    vso_org.add_user(vso_user)
  end

  let(:user) { create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"]) }
  let!(:vso_participant_id) { "54321" }
  let!(:vso_org) { create(:vso, name: "VSO", role: "VSO", participant_id: vso_participant_id) }
  let!(:vso_user) { create(:user, css_id: "BILLIE_VSO", roles: ["VSO"], email: "BILLIE@test.com") }
  let!(:coordinator) { create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG") }
  let!(:vlj) { create(:staff, :judge_role, snamef: "HIJ", snamel: "LMNO") }
  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "C", scheduled_time: "12:00AM") }
  let(:expected_alert) { COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name }
  let(:virtual_hearing_alert) do
    COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
  end
  let!(:virtual_hearing_success_alert) do
    COPY::VIRTUAL_HEARING_SUCCESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
  end

  let(:pre_loaded_veteran_email) { hearing.appeal.veteran.email_address }
  let(:pre_loaded_rep_email) { hearing.appeal.representative_email_address }
  let(:fill_in_veteran_email) { "veteran@example.com" }
  let(:fill_in_veteran_tz) { "Eastern Time (US & Canada)" }
  let(:fill_in_rep_email) { "rep@testingEmail.com" }
  let(:fill_in_rep_tz) { "Mountain Time (US & Canada)" }
  let(:pexip_url) { "fake.va.gov" }

  def check_row_content(event, index)
    # Format the date the same as moment
    formatted_date = event.sent_at.strftime("%b %d, %Y, %-l:%M %P %Z").gsub(/DT/, "ST")

    expect(find("#table-row-#{index} > td:first-child")).to have_content(event.sent_to_role)
    expect(find("#table-row-#{index} > td:nth-child(2)")).to have_content(event.email_address)
    expect(find("#table-row-#{index} > td:nth-child(3)")).to have_content(formatted_date)
    expect(find("#table-row-#{index} > td:last-child")).to have_content(event.sent_by.username)
  end

  def check_email_event_rows(hearing, row_count)
    within "#hearingEmailEvents table > tbody" do
      # Expecting 2 because rep email is filled as well
      expect(find_all("tr").length).to eq(row_count)

      hearing.email_events.order(sent_at: :desc).map.with_index do |event, index|
        check_row_content(event, index)
      end
    end
  end

  def check_email_event_headers
    expect(page).to have_selector("#hearingEmailEvents")

    within "#hearingEmailEvents table > thead > tr" do
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
    # Confirm that the host hearing link details exist
    within "#vlj-hearings-link" do
      find("div", text: "Conference Room: #{virtual_hearing.formatted_alias_or_alias_with_host}")
      find("div", text: "PIN: #{virtual_hearing.host_pin}")
      ensure_link_present(virtual_hearing.host_link, disable_link)
    end
    # Confirm that the guest hearing link details exist
    within "#guest-hearings-link" do
      find("div", text: "Conference Room: #{virtual_hearing.formatted_alias_or_alias_with_host}")
      find("div", text: "PIN: #{virtual_hearing.guest_pin}")
      ensure_link_present(virtual_hearing.guest_link, disable_link)
    end
  end

  def ensure_link_present(link, disable)
    expect(page).to have_selector(:css, "a[href='#{link}']") unless disable
  end

  shared_examples "always updatable fields" do
    scenario "user can select judge, hearing room, hearing coordinator, and add notes" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      # wait until the label displays before trying to interact with the dropdowns
      find("div", class: "dropdown-judgeDropdown", text: COPY::DROPDOWN_LABEL_JUDGE)
      find("div", class: "dropdown-hearingCoordinatorDropdown", text: COPY::DROPDOWN_LABEL_HEARING_COORDINATOR)
      find("div", class: "dropdown-hearingRoomDropdown", text: COPY::DROPDOWN_LABEL_HEARING_ROOM)

      click_dropdown(name: "judgeDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingCoordinatorDropdown", index: 0, wait: 30)
      click_dropdown(name: "hearingRoomDropdown", index: 0, wait: 30)

      if hearing.is_a?(Hearing)
        find("label", text: "Yes, Waive 90 Day Evidence Hold").click
      end

      fill_in "Notes", with: generate_words(10)

      # Save the edited fields
      click_button("Save")

      expect(page).to have_content(expected_alert)
    end
  end

  shared_examples "non-virtual hearing types" do
    scenario "user can convert hearing type to virtual" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

      fill_in "Veteran Email (for these notifications only)", with: fill_in_veteran_email
      fill_in "POA/Representative Email (for these notifications only)", with: fill_in_rep_email

      # Update the POA and Appellant timezones
      click_dropdown(name: "representativeTz", text: fill_in_rep_tz)
      click_dropdown(name: "appellantTz", text: fill_in_veteran_tz)
      click_dropdown(name: "judgeDropdown", index: 0, wait: 30)

      click_button("Save")

      hearing.reload

      # Check the Email Notification History
      check_email_event_table(hearing, 2)

      # Check the emails were sent to the correct address
      hearing.email_events.each do |event|
        expect(page).to have_content(event.email_address)
      end
      expect(page).to have_content(expected_alert)

      # Ensure the emails and timezone were updated
      expect(page).to have_field("Veteran Email", with: fill_in_veteran_email)
      expect(page).to have_field("POA/Representative Email", with: fill_in_rep_email)
      expect(page).to have_content(fill_in_veteran_tz)
      expect(page).to have_content(fill_in_rep_tz)

      check_virtual_hearings_links(hearing.virtual_hearing)
    end

    scenario "user can optionally change emails and timezone" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      # Update the POA and Appellant emails
      fill_in "Veteran Email", with: fill_in_veteran_email
      fill_in "POA/Representative Email", with: fill_in_rep_email

      # Update the POA and Appellant timezones
      click_dropdown(name: "representativeTz", text: fill_in_rep_tz)
      click_dropdown(name: "appellantTz", text: fill_in_veteran_tz)

      click_button("Save")

      expect(page).to have_content(expected_alert)
      expect(page).to have_field("Veteran Email", with: fill_in_veteran_email)
      expect(page).to have_field("POA/Representative Email", with: fill_in_rep_email)
      expect(page).to have_content(fill_in_veteran_tz)
      expect(page).to have_content(fill_in_rep_tz)
    end

    scenario "vso users are taken to case details page instead of the hearing details
       if they click cancel" do
      User.authenticate!(user: vso_user)

      # Ensure user was on Case Details page first so goBack() takes user back to the correct page.
      visit "/queue/appeals/#{hearing.appeal_external_id}"
      visit "hearings/" + hearing.external_id.to_s + "/details"

      expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

      click_button("Cancel")

      expect(page).to have_current_path("/queue/appeals/#{hearing.appeal_external_id}")
    end

    scenario "vso user can convert hearing type to virtual" do
      User.authenticate!(user: vso_user)

      visit "hearings/" + hearing.external_id.to_s + "/details"

      expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

      fill_in "Veteran Email", with: fill_in_veteran_email
      fill_in "Confirm Veteran Email", with: fill_in_veteran_email

      # Update the POA and Appellant Timezones
      click_dropdown(name: "representativeTz", index: 5)
      click_dropdown(name: "appellantTz", index: 2)

      click_label "affirmPermission"
      click_label "affirmAccess"

      click_button("Save")

      appeal_id = hearing.appeal.is_a?(Appeal) ? hearing.appeal.uuid : hearing.appeal.external_id
      expect(page).to have_current_path("/queue/appeals/#{appeal_id}")

      appellant_name = if hearing.appeal.appellant_is_not_veteran
                         "#{hearing.appellant_first_name} #{hearing.appellant_last_name}"
                       else
                         "#{hearing.veteran_first_name} #{hearing.veteran_last_name}"
                       end

      success_title = format(COPY::CONVERT_HEARING_TYPE_SUCCESS, appellant_name, "virtual")

      expect(page).to have_content(success_title)
      expect(page).to have_content(COPY::VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL)
    end
  end

  shared_examples "all hearing types" do
    context "when type is Video" do
      before do
        User.authenticate!(user: user)
        hearing.hearing_day.update!(regional_office: "RO06", request_type: "V")
      end
      include_examples "always updatable fields"
      include_examples "non-virtual hearing types"
    end

    context "when type is Central" do
      before do
        hearing.hearing_day.update!(regional_office: nil, request_type: "C")

        if hearing.is_a?(LegacyHearing)
          hearing.update(original_vacols_request_type: "C")
        end
      end

      include_examples "always updatable fields"
      include_examples "non-virtual hearing types"
    end

    context "when type is Virtual" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :initialized,
          status: :active,
          hearing: hearing,
          appellant_email: "existing_veteran_email@caseflow.gov",
          appellant_email_sent: true,
          judge_email: "existing_judge_email@caseflow.gov",
          judge_email_sent: true,
          representative_email: nil
        )
      end

      include_examples "always updatable fields"

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

        let(:virtual_hearing_alert) do
          COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_FROM_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
        end
        let!(:expected_alert) do
          COPY::VIRTUAL_HEARING_SUCCESS_ALERTS["CHANGED_FROM_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
        end

        scenario "user can optionally change emails and timezone" do
          visit "hearings/" + hearing.external_id.to_s + "/details"

          # Change the hearing type
          click_dropdown(name: "hearingType", index: 0)

          # Update the POA and Appellant emails
          fill_in "Veteran Email (for these notifications only)", with: fill_in_veteran_email
          fill_in "POA/Representative Email (for these notifications only)", with: fill_in_rep_email

          # Update the POA and Appellant timezones
          click_dropdown(name: "representativeTz", text: fill_in_rep_tz)
          click_dropdown(name: "appellantTz", text: fill_in_veteran_tz)
          expect(page).to have_no_field("judgeDropdown")

          # Confirm the Modal change to cancel the virtual hearing
          click_button("Convert to #{hearing.readable_request_type} Hearing")

          # Ensure the emails and timezone were updated
          expect(page).to have_field("Veteran Email", with: fill_in_veteran_email)
          expect(page).to have_field("POA/Representative Email", with: fill_in_rep_email)
          expect(page).to have_content(fill_in_veteran_tz)
          expect(page).to have_content(fill_in_rep_tz)
        end

        scenario "email notifications and links display correctly" do
          visit "hearings/" + hearing.external_id.to_s + "/details"

          click_dropdown(name: "hearingType", index: 0)

          # Confirm the Modal change to cancel the virtual hearing
          click_button("Convert to #{hearing.readable_request_type} Hearing")

          expect(page).to have_content(virtual_hearing_alert)
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
            hearing.update(hearing_day_id: hearing_day.id)
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
            virtual_hearing.hearing.appellant_recipient.update!(email_sent: false)
            virtual_hearing.hearing.representative_recipient.update!(email_sent: false)
            virtual_hearing.hearing.judge_recipient.update!(email_sent: false)
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
        let(:fill_in_veteran_email) { "veteran@example.com" }
        let(:fill_in_rep_email) { "rep@example.com" }

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

          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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

          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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
          click_button(COPY::VIRTUAL_HEARING_UPDATE_EMAIL_BUTTON, wait: 5)

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

          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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
          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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

          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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

          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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

          events = SentHearingEmailEvent.where(hearing_id: hearing.id)
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
  end

  context "with unauthorized user role (non-hearings management)" do
    let!(:current_user) { User.authenticate!(user: user) }

    scenario "Fields are not editable" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to have_field("Notes", disabled: true)
    end
  end

  context "with authorized user role" do
    let!(:current_user) do
      HearingsManagement.singleton.add_user(user)
      User.authenticate!(user: user)
    end
    let(:expected_alert) { COPY::HEARING_UPDATE_SUCCESSFUL_TITLE % hearing.appeal.veteran.name }

    context "when hearing is AMA" do
      include_examples "all hearing types"

      scenario "user can update transcription fields" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        fill_in "taskNumber", with: "123456789"
        click_dropdown(name: "transcriber", index: 1)
        fill_in "sentToTranscriberDate", with: "04012019"
        fill_in "expectedReturnDate", with: "04022019"
        fill_in "uploadedToVbmsDate", with: "04032019"

        click_dropdown(name: "problemType", index: 1)
        fill_in "problemNoticeSentDate", with: "04042019"
        find(
          ".cf-form-radio-option",
          text: Constants.TRANSCRIPTION_REQUESTED_REMEDIES.PROCEED_WITHOUT_TRANSCRIPT
        ).click

        find("label", text: "Yes, Transcript Requested").click
        fill_in "copySentDate", with: "04052019"

        click_button("Save")

        expect(page).to have_content(expected_alert)
      end

      context "when hearing already has transcription details" do
        let!(:transcription) do
          create(
            :transcription,
            hearing: hearing,
            problem_type: Constants.TRANSCRIPTION_PROBLEM_TYPES.POOR_AUDIO,
            requested_remedy: Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING
          )
        end

        # This test ensures that a bug related to sending partial form data is fixed.
        #   See: https://github.com/department-of-veterans-affairs/caseflow/issues/14130
        scenario "can update fields without side-effects to transcription" do
          visit "hearings/#{hearing.external_id}/details"

          step "ensure page has existing transcription details" do
            expect(
              page.find(".dropdown-problemType .cf-select__value-container")
            ).to have_content(Constants.TRANSCRIPTION_PROBLEM_TYPES.POOR_AUDIO)
            expect(
              find_field(Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING, visible: false)
            ).to be_checked
          end

          step "changing only problem type preserves already populated fields" do
            click_dropdown(name: "problemType", index: 0)
            click_button("Save")

            expect(page).to have_content(expected_alert)

            visit "hearings/#{hearing.external_id}/details"

            expect(
              page.find(".dropdown-problemType .cf-select__value-container")
            ).to have_content(Constants.TRANSCRIPTION_PROBLEM_TYPES.NO_AUDIO)
            expect(
              find_field(Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING, visible: false)
            ).to be_checked
            expect(Transcription.count).to be(2)
          end

          step "changing notes preserves already populated fields and doesn't create new transcription" do
            fill_in "Notes", with: "Test Notes Test Notes"
            click_button("Save")

            expect(page).to have_content(expected_alert)

            visit "hearings/#{hearing.external_id}/details"

            expect(page).to have_content("Test Notes Test Notes")
            expect(
              page.find(".dropdown-problemType .cf-select__value-container")
            ).to have_content(Constants.TRANSCRIPTION_PROBLEM_TYPES.NO_AUDIO)
            expect(
              find_field(Constants.TRANSCRIPTION_REQUESTED_REMEDIES.NEW_HEARING, visible: false)
            ).to be_checked
            expect(Transcription.count).to be(2)
          end
        end
      end
    end

    context "when hearing is Legacy" do
      let!(:hearing) { create(:legacy_hearing, :with_tasks, regional_office: "RO06") }

      include_examples "all hearing types"

      context "when type is Travel" do
        before do
          hearing.hearing_day.update!(regional_office: "RO06", request_type: "T")
          hearing.update(original_vacols_request_type: "T")
        end

        include_examples "always updatable fields"
        include_examples "non-virtual hearing types"
      end

      scenario "user cannot update transcription fields" do
        visit "hearings/" + hearing.external_id.to_s + "/details"

        expect(page).to have_no_field("taskNumber")
        expect(page).to have_no_field("transcriber")
        expect(page).to have_no_field("sentToTranscriberDate")
        expect(page).to have_no_field("expectedReturnDate")
        expect(page).to have_no_field("uploadedToVbmsDate")
        expect(page).to have_no_field("problemType")
        expect(page).to have_no_field("problemNoticeSentDate")
        expect(page).to have_no_field("requestedRemedy")
        expect(page).to have_no_field("copySentDate")
        expect(page).to have_no_field("copyRequested")
      end
    end
  end

  context "with VSO user role" do
    let(:expected_veteran_email) { hearing.appeal.appellant_email_address }

    scenario "user is immediately redirected to the Convert to Virtual form" do
      step "hearing is not virtual on hearing itself and appeal" do
        expect(hearing.virtual?).to eq false
        expect(hearing.appeal.changed_hearing_request_type).to_not eq Constants.HEARING_REQUEST_TYPES.virtual
      end

      User.authenticate!(user: vso_user)
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to have_content(format(COPY::CONVERT_HEARING_TITLE, "Virtual"))
      expect(page).to have_content(COPY::CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_ACCESS)
      expect(page).to have_content(COPY::CONVERT_HEARING_TYPE_CHECKBOX_AFFIRM_PERMISSION)
      expect(page).to have_content(COPY::CONVERT_HEARING_TYPE_SUBTITLE_3)
      expect(page).to_not have_content(COPY::CENTRAL_OFFICE_CHANGE_TO_VIRTUAL)

      step "the submit button is disabled at first" do
        # Veteran email field should be pre-populated.
        expect(page).to have_field("Veteran Email", with: expected_veteran_email)
        fill_in "Confirm Veteran Email", with: expected_veteran_email

        # Update the POA and Appellant Timezones
        click_dropdown(name: "representativeTz", index: 1)
        click_dropdown(name: "appellantTz", index: 5)

        expect(page).to have_button("Save", disabled: true)
        expect(page).to have_current_path("/hearings/" + hearing.external_id.to_s + "/details")
      end

      step "the submit button is disabled after one checkbox is selected" do
        click_label "affirmPermission"
        expect(page).to have_button("Save", disabled: true)
        expect(page).to have_current_path("/hearings/" + hearing.external_id.to_s + "/details")
      end

      step "the submit button goes through after both checkboxes are selected" do
        click_label "affirmAccess"
        expect(page).to have_button("Save", disabled: false)
        click_button("Save")
        # expect success
        expect(page).to have_current_path("/queue/appeals/#{hearing.appeal_external_id}")

        # might not need all of this
        appellant_name = if hearing.appeal.appellant_is_not_veteran
                           "#{hearing.appellant_first_name} #{hearing.appellant_last_name}"
                         else
                           "#{hearing.veteran_first_name} #{hearing.veteran_last_name}"
                         end

        success_title = format(COPY::CONVERT_HEARING_TYPE_SUCCESS, appellant_name, "virtual")

        expect(page).to have_content(success_title)
        expect(page).to have_content(COPY::VSO_CONVERT_HEARING_TYPE_SUCCESS_DETAIL)
      end

      step "hearing is now virtual on both hearing itself and its appeal" do
        hearing.reload

        expect(hearing.virtual?).to eq true
        expect(hearing.appeal.changed_hearing_request_type).to eq Constants.HEARING_REQUEST_TYPES.virtual
      end

      step "hearing email recipients have been recorded and emails notifications have been sent" do
        expect(hearing.appellant_recipient.email_address).to eq expected_veteran_email
        expect(hearing.representative_recipient.email_address).to eq current_user.email

        expect(hearing.email_events.count).to eq 2
      end
    end

    scenario "convert to virtual form hides sensitive data for vso user" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      ["Hearing Time", "Hearing Date"].each do |label|
        expect(page).to_not have_content(label)
      end
    end
  end

  context "with hearings scheduler user role" do
    before do
      User.authenticate!(user: user)
    end

    scenario "user is not immediately redirected to the convert to virtual hearing form" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(page).to_not have_content(format(COPY::CONVERT_HEARING_TITLE, "Virtual"))
    end

    scenario "user can visit convert to virtual hearing form" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")

      click_button("Cancel")
    end

    scenario "convert to virtual hearing form does not hide data for hearings user" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content(COPY::CONVERT_HEARING_TITLE % "Virtual")
      ["Hearing Time", "Hearing Date"].each do |label|
        expect(page).to have_content(label)
      end
    end
  end
end
