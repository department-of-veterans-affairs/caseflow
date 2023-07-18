# frozen_string_literal: true

RSpec.feature "CAVC Dashboard", :all_dbs do
  let(:legacy_appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
  let(:non_cavc_appeal) { create(:appeal, :direct_review_docket) }
  let(:cavc_remand) { create(:cavc_remand) }
  let(:authorized_user) { create(:user) }
  let(:unauthorized_user) { create(:user) }
  let(:occteam_organization) { OccTeam.singleton }
  let(:oaiteam_organization) { OaiTeam.singleton }

  context "user is not a member of OAI or OCC organization" do
    before { User.authenticate!(user: unauthorized_user) }

    it "user cannot see the CAVC Dashboard button on the remand appeal case details page" do
      visit "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"
      reload_case_detail_page(cavc_remand.remand_appeal.uuid)
      expect(page).to have_text "CAVC Remand"
      expect(page).not_to have_text "CAVC Dashboard"
    end
  end

  context "as an OCC user cannot add issues to the cavc dashboard" do
    before do
      occteam_organization.add_user(unauthorized_user)
      User.authenticate!(user: unauthorized_user)
      occteam_organization.add_user(unauthorized_user)
    end

    it "dashboard loads as read-only if the appeal has an associated cavcRemand" do
      go_to_dashboard(cavc_remand.remand_appeal.uuid)
      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      expect(page).to_not have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
      expect(page).to_not have_content("Edit")
    end
  end

  context "as an OAI user" do
    before do
      oaiteam_organization.add_user(authorized_user)
      User.authenticate!(user: authorized_user)
      oaiteam_organization.add_user(authorized_user)
    end

    it "dashboard cancel button returns to case details if no changes have been made" do
      go_to_dashboard(cavc_remand.remand_appeal.uuid)
      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      expect(page).to have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
      expect(page).to have_content("Edit")

      expect(page).to have_button("Save Changes", disabled: true)
      expect(page).to have_button("Cancel")
      click_button "Cancel"

      expect(page).to have_current_path "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"
    end

    it "dashboard save button is disabled until changes made, cancel button shows warning if clicked without saving" do
      go_to_dashboard(cavc_remand.remand_appeal.uuid)
      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      expect(page).to have_content(COPY::ADD_CAVC_DASHBOARD_ISSUE_BUTTON_TEXT)
      expect(page).to have_content("Edit")

      expect(page).to have_button("Save Changes", disabled: true)
      page.all("div.cf-select__placeholder", exact_text: "Select option").first.click
      page.find("div.cf-select__menu").find("div", exact_text: "Abandoned").click
      expect(page).to have_button("Save Changes", disabled: false)
      click_button "Cancel"

      expect(page).to have_content(COPY::CANCEL_CAVC_DASHBOARD_CHANGE_MODAL_HEADER)
      expect(page).to have_button("Continue")
      click_button "Continue"

      expect(page).to have_current_path "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"
      click_button "CAVC Dashboard"
      expect(page).not_to have_content("Abandoned")
    end

    it "cancel modal functions properly when changes have not been saved" do
      go_to_dashboard(cavc_remand.remand_appeal.uuid)
      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      expect(page).to have_content("Edit")

      page.all("div.cf-select__placeholder", exact_text: "Select option").first.click
      page.find("div.cf-select__menu").find("div", exact_text: "Abandoned").click
      expect(page).to have_button("Save Changes", disabled: false)
      expect(page).to have_button("Cancel")
      click_button "Cancel"

      expect(page).to have_content(COPY::CANCEL_CAVC_DASHBOARD_CHANGE_MODAL_HEADER)
      expect(page).to have_button("Cancel")

      page.find("button", id: "Your-changes-are-not-saved-button-id-0").click

      expect(page).to have_text `CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}`
      click_button "Cancel"

      expect(page).to have_button("Continue")
      click_button "Continue"
      expect(page).to have_current_path "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"
    end

    it "user can edit and save CAVC remand details" do
      go_to_dashboard(cavc_remand.remand_appeal.uuid)

      page.find("button", text: "Edit").click

      modal = page.find("div.cf-modal-body")
      within(modal) do
        fill_in(name: "Board Decision Date", with: "01/01/2021")
        fill_in(name: "Board Docket Number", with: "210101-1000")
        fill_in(name: "CAVC Decision Date", with: "01/01/2021")
        fill_in(name: "CAVC Docket Number", with: "21-1234")
        find("label", text: "No").click
      end

      click_button "Save"

      expect(page).to have_content `CAVC appeal 21-1234`
      # date format for input is MM/DD/YYYY but for display is MM/DD/YY
      expect(page).to have_content "01/01/21"
      expect(page).to have_content "210101-1000"
      expect(page).to have_content "01/01/21"
      expect(page).to have_content "21-1234"
      expect(page).to have_content "No"

      dashboard = CavcDashboard.find_by(cavc_remand: cavc_remand)
      expect(dashboard.board_decision_date).to eq "01/01/2021".to_date
      expect(dashboard.board_docket_number).to eq "210101-1000"
      expect(dashboard.cavc_decision_date).to eq "01/01/2021".to_date
      expect(dashboard.cavc_docket_number).to eq "21-1234"
      expect(dashboard.joint_motion_for_remand).to eq false
    end

    it "user can add issues, edit dispsositions, and save changes" do
      issue_description = "Test Issue Description"
      Seeds::CavcDecisionReasonData.new.seed!

      go_to_dashboard(cavc_remand.remand_appeal.uuid)

      dropdowns = page.all("div.cf-select__placeholder", exact_text: "Select option")

      dropdowns.each do |dropdown|
        dropdown.click
        page.find("div.cf-select__menu").find("div", exact_text: "Abandoned").click
      end

      click_button "Add issue"
      modal = page.find("div.cf-modal-body")
      within(modal) do
        benefit_type_dropdown = page.find("div.cf-form-dropdown", text: "Benefit type")
        benefit_type_dropdown.find("div.cf-select").click
        benefit_type_dropdown.find("div.cf-select__menu").find("div", exact_text: "Compensation").click

        issue_cat_dropdown = page.find("div.cf-form-dropdown", text: "Issue category")
        issue_cat_dropdown.find("div.cf-select").click
        issue_cat_dropdown.find("div.cf-select__menu").find("div", exact_text: "Other Non-Rated").click

        disp_dropdown = page.find("div.cf-form-dropdown", text: "Disposition by Court")
        disp_dropdown.find("div.cf-select").click
        disp_dropdown.find("div.cf-select__menu").find("div", exact_text: "Affirmed").click

        fill_in(name: "Issue Description", with: issue_description)

        click_button "Add issue"
      end

      click_button "Save Changes"

      expect(page).to have_current_path "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"
      click_button "CAVC Dashboard"

      abandoned = page.all("div.cf-select__value-container", exact_text: "Abandoned")
      affirmed = page.all("div.cf-select__value-container", exact_text: "Affirmed")
      expect(page).to have_content issue_description
      expect(abandoned.count).to eq 3
      expect(affirmed.count).to eq 1
    end

    it "user can set decision reasons for Vacated and Remanded or Reversed decision types and save" do
      Seeds::CavcDecisionReasonData.new.seed!
      Seeds::CavcSelectionBasisData.new.seed!

      go_to_dashboard(cavc_remand.remand_appeal.uuid)

      expect(page).to have_text "CAVC appeals for #{cavc_remand.remand_appeal.veteran.name}"

      page.all("div.cf-select__placeholder", exact_text: /Select option/).first.click
      page.find("div.cf-select__menu").find("div", exact_text: "Reversed").click

      reversed_section = page.all("div.usa-accordion-bordered").first
      reversed_section.click
      reversed_section.find("span", exact_text: "Duty to notify").click
      reversed_section.find("span", exact_text: "Duty to assist").click
      reversed_section.find("span", exact_text: "Treatment records").click
      expect(page).to have_content "Decision Reasons (2)"
      reversed_section.find("div", exact_text: "Decision Reasons (2)").click
      expect(page).to have_css('div[aria-expanded="false"]')

      scroll_to page.find("button.cf-submit", text: "Save Changes")
      page.all("div.cf-select__placeholder", exact_text: /Select option/).last.click
      page.find("div.cf-select__menu").find("div", exact_text: "Vacated and Remanded").click

      v_and_r_section = page.all("div.usa-accordion-bordered").last
      v_and_r_section.click
      v_and_r_section.find("span", exact_text: "AMA specific remand").click
      v_and_r_section.find("span", exact_text: "Issuing a decision before 90-day window closed").click
      v_and_r_section.find("span", exact_text: "Other").click
      click_button "Add basis"
      other_dropdown = page.find("div.cf-form-dropdown", text: "Type to search...")
      other_dropdown.find("div.cf-select").click
      other_dropdown.find("input").send_keys "oth"
      other_dropdown.find("div.cf-select__menu").all("div", exact_text: "Other").last.click
      v_and_r_section.find("input.cf-form-textinput").click.send_keys "Test New Basis"

      expect(page).to have_content "Decision Reasons (1)"
      v_and_r_section.find("div", exact_text: "Decision Reasons (1)").click

      scroll_to page.find("button", text: "Save Changes")
      click_button "Save Changes"
      reload_case_detail_page(cavc_remand.remand_appeal.uuid)
      expect(page).to have_current_path "/queue/appeals/#{cavc_remand.remand_appeal.uuid}"
      click_button "CAVC Dashboard"

      expect(page).to have_content "Decision Reasons (2)"
      expect(page).to have_content "Decision Reasons (1)"
      page.all("div", text: "Decision Reasons (1)").last.click
      scroll_to page.find("button", text: "Remove basis")
      expect(page).to have_content "Test New Basis"
    end
  end
end

def go_to_dashboard(appeal_uuid)
  reload_case_detail_page(appeal_uuid)
  click_button "CAVC Dashboard"
  expect(page).to have_current_path("/queue/appeals/#{appeal_uuid}/cavc_dashboard", ignore_query: true)
end
