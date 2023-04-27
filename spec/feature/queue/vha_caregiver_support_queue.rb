# frozen_string_literal: true

feature "VhaCaregiverSupportQueue", :all_dbs do
  context "Load Caregiver Support Queue" do
    let(:csp_org) { VhaCaregiverSupport.singleton }
    let(:csp_user) { User.authenticate!(roles: ["CAREGIVERADMIN"]) }
    let(:unassigned_tab_text) { "Unassigned" }
    let(:in_progress_tab_text) { "In Progress" }
    let(:completed_tab_text) { "Completed" }
    let(:column_heading_names) do
      [
        "Case Details", "Tasks", "Assigned By", "Types", "Docket", "Days Waiting", "Veteran Documents"
      ]
    end
    let!(:num_unassigned_rows) { 3 }
    let!(:num_in_progress_rows) { 9 }
    let!(:num_completed_rows) { 5 }

    let!(:vha_caregiver_unassigned_tasks) do
      create_list(:vha_document_search_task, num_unassigned_rows, :assigned, assigned_to: csp_org)
    end
    let!(:vha_caregiver_in_progress_tasks) do
      create_list(:vha_document_search_task, num_in_progress_rows, :in_progress, assigned_to: csp_org)
    end
    let!(:vha_caregiver_completed_tasks) do
      create_list(:vha_document_search_task, num_completed_rows, :completed, assigned_to: csp_org)
    end

    before do
      csp_org.add_user(csp_user)
      csp_user.reload
      visit "/organizations/#{csp_org.url}"
    end

    scenario "Caregiver Support Queue Loads" do
      expect(find("h1")).to have_content("VHA Caregiver Support Program cases")
    end

    # TODO: Replace all these with the new shared examples when issue type is added to caregiver.

    scenario "CSP Queue Has unassigned, in progress, and completed tabs" do
      expect(page).to have_content unassigned_tab_text
      expect(page).to have_content in_progress_tab_text
      expect(page).to have_content completed_tab_text
    end

    scenario "CSP Queue Unassigned tab has the correct column Headings and description text" do
      # The first tab is the unassigned tab so there is no need to navigate
      html_table_headings = all("th").map(&:text).reject(&:empty?).compact
      expect(page).to have_content "Cases assigned to VHA Caregiver Support Program:"
      expect(html_table_headings).to eq(column_heading_names)
    end

    scenario "CSP Queue In Progress tab has the correct column Headings and description text" do
      # Navigate to the In Progress Tab
      click_button(in_progress_tab_text)

      html_table_headings = all("th").map(&:text).reject(&:empty?).compact
      expect(page).to have_content "Cases assigned to VHA Caregiver Support Program:"
      expect(html_table_headings).to eq(column_heading_names)
    end

    scenario "CSP Queue Completed tab has the correct column Headings and description text" do
      # Navigate to the Completed Tab
      click_button(completed_tab_text)

      html_table_headings = all("th").map(&:text).reject(&:empty?).compact
      expect(page).to have_content "Cases completed (last 7 days):"
      expect(html_table_headings).to eq(column_heading_names)
    end

    scenario "CSP Queue Unassigned tab has the correct number in the tab name and the number of table rows" do
      unassigned_tab_button = find("button", text: unassigned_tab_text)
      num_table_rows = all("tbody > tr").count
      expect(unassigned_tab_button.text).to eq("#{unassigned_tab_text} (#{num_unassigned_rows})")
      expect(num_table_rows).to eq(num_unassigned_rows)
    end

    scenario "CSP Queue In Progress tab has the correct number in the tab name and the number of table rows" do
      # Navigate to the In Progress Tab
      in_progress_tab_button = find("button", text: in_progress_tab_text)
      in_progress_tab_button.click
      num_table_rows = all("tbody > tr").count
      expect(in_progress_tab_button.text).to eq("#{in_progress_tab_text} (#{num_in_progress_rows})")
      expect(num_table_rows).to eq(num_in_progress_rows)
    end

    scenario "CSP Queue Completed tab has the correct number of table rows" do
      # Navigate to the Completed Tab
      click_button(completed_tab_text)
      num_table_rows = all("tbody > tr").count
      expect(num_table_rows).to eq(num_completed_rows)
    end
  end
end
