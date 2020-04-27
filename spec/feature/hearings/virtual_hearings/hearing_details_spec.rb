# frozen_string_literal: true

RSpec.feature "Editing Virtual Hearings from Hearing Details", :all_dbs do
  let(:current_user) { create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"]) }

  before do
    create(:staff, sdept: "HRG", sactive: "A", snamef: "ABC", snamel: "EFG")
    create(:staff, svlj: "J", sactive: "A", snamef: "HIJ", snamel: "LMNO")
    HearingsManagement.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
    FeatureToggle.enable!(:schedule_virtual_hearings)
  end

  let!(:hearing) { create(:hearing, :with_tasks, regional_office: "RO13") }
  let!(:expected_alert) do
    COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_TO_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
  end

  let(:pre_loaded_veteran_email) { hearing.appeal.veteran.email_address }
  let(:pre_loaded_rep_email) { hearing.appeal.representative_email_address }
  let(:fill_in_veteran_email) { "email@testingEmail.com" }

  context "user switches hearing type to 'Virtual'" do
    scenario "veteran and representative emails are pre loaded" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      click_dropdown(name: "hearingType", index: 1)
      expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE)
      expect(page).to have_field("Veteran Email", with: pre_loaded_veteran_email)
      expect(page).to have_field("POA/Representative Email", with: pre_loaded_rep_email)
    end

    scenario "hearing is switched to 'Virtual'" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      click_dropdown(name: "hearingType", index: 1)
      expect(page).to have_content(COPY::VIRTUAL_HEARING_MODAL_CHANGE_TO_VIRTUAL_TITLE)

      fill_in "vet-email", with: fill_in_veteran_email
      click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

      expect(page).to have_content(expected_alert)

      hearing.reload
      expect(VirtualHearing.count).to eq(1)
      expect(hearing.virtual?).to eq(true)
      expect(hearing.virtual_hearing.veteran_email).to eq("email@testingEmail.com")
      expect(hearing.virtual_hearing.representative_email).to eq(pre_loaded_rep_email)
      expect(hearing.virtual_hearing.judge_email).to eq(nil)

      # check for SentHearingEmailEvents
      events = SentHearingEmailEvent.where(hearing_id: hearing.id)
      expect(events.count).to eq 2
      expect(events.where(sent_by_id: current_user.id).count).to eq 2
      expect(events.where(email_type: "confirmation").count).to eq 2
      expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
      expect(events.where(recipient_role: "veteran").count).to eq 1
      expect(events.where(email_address: pre_loaded_rep_email).count).to eq 1
      expect(events.where(recipient_role: "representative").count).to eq 1
    end
  end

  context "for an existing Virtual Hearing" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing,
        :all_emails_sent,
        status: :active,
        hearing: hearing
      )
    end
    let!(:expected_alert) do
      COPY::VIRTUAL_HEARING_PROGRESS_ALERTS["CHANGED_FROM_VIRTUAL"]["TITLE"] % hearing.appeal.veteran.name
    end

    scenario "user switches hearing type back to original request type" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      click_dropdown(name: "hearingType", index: 0)
      expect(page).to have_content("Change to")

      click_button(COPY::VIRTUAL_HEARING_CHANGE_HEARING_BUTTON)

      expect(page).to have_content(expected_alert)

      virtual_hearing.reload
      expect(virtual_hearing.cancelled?).to eq(true)
      expect(page).to have_content(hearing.readable_request_type)
    end
  end

  context "Hearing type dropdown and vet and poa fields are disabled while async job is running" do
    let!(:virtual_hearing) { create(:virtual_hearing, :all_emails_sent, hearing: hearing) }

    scenario "async job is not completed" do
      visit "hearings/" + hearing.external_id.to_s + "/details"
      expect(find(".dropdown-hearingType")).to have_css(".is-disabled")
      expect(page).to have_field("Veteran Email", readonly: true)
      expect(page).to have_field("POA/Representative Email", readonly: true)
    end

    scenario "async job is completed" do
      virtual_hearing.conference_id = "0"
      virtual_hearing.established!
      visit "hearings/" + hearing.external_id.to_s + "/details"
      hearing.reload
      expect(find(".dropdown-hearingType")).to have_no_css(".is-disabled")
      expect(page).to have_field("Veteran Email", readonly: false)
      expect(page).to have_field("POA/Representative Email", readonly: false)
    end
  end

  context "User can see and edit veteran and poa emails" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing,
        :all_emails_sent,
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

      events = SentHearingEmailEvent.where(hearing_id: hearing.id)
      expect(events.count).to eq 2
      expect(events.where(sent_by_id: current_user.id).count).to eq 2
      expect(events.where(email_type: "confirmation").count).to eq 2
      expect(events.where(email_address: fill_in_veteran_email).count).to eq 1
      expect(events.where(recipient_role: "veteran").count).to eq 1
      expect(events.where(email_address: fill_in_rep_email).count).to eq 1
      expect(events.where(recipient_role: "representative").count).to eq 1
    end
  end

  context "User has the correct link" do
    let!(:virtual_hearing) do
      create(
        :virtual_hearing,
        :initialized,
        :all_emails_sent,
        status: :active,
        hearing: hearing
      )
    end

    scenario "user has the host link" do
      visit "hearings/" + hearing.external_id.to_s + "/details"

      expect(page).to have_content(
        "conference=#{virtual_hearing.formatted_alias_or_alias_with_host}&
        pin=#{virtual_hearing.host_pin}#
        &join=1&role=host"
      )
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
end
