# frozen_string_literal: true

feature "VhaRegionalQueue", :all_dbs do
  def a_normal_tab(expected_text)
    # a normal tab should have same column header and should also contain Paging information
    html_table_headings = all("th").map(&:text).reject(&:empty?).compact
    expect(html_table_headings).to eq(column_heading_names)
    expect(page).to have_text expected_text
  end

  context "Load VhaRegional Queue aka VISN" do
    let(:regional_office) { create(:vha_regional_office) }
    let(:regional_office_user) { create(:user) }
    let(:assigned_tab_text) { "Assigned" }
    let(:in_progress_tab_text) { "In Progress" }
    let(:on_hold_tab_text) { "On Hold" }
    let(:completed_tab_text) { "Completed" }
    let(:assigned_pagination_text) { "Viewing 1-#{num_assigned_rows} of #{num_assigned_rows} total" }
    let(:in_progress_pagination_text) { "Viewing 1-#{num_in_progress_rows} of #{num_in_progress_rows} total" }
    let(:completed_pagination_text) { "Viewing 1-#{num_completed_rows} of #{num_completed_rows} total" }
    let(:on_hold_pagination_text) { "Viewing 1-#{num_on_hold_rows} of #{num_on_hold_rows} total" }
    let(:column_heading_names) do
      [
        "Case Details", "Issue Type", "Tasks", "Assigned By", "Types", "Docket", "Days Waiting", "Veteran Documents"
      ]
    end
    let!(:num_assigned_rows) { 3 }
    let!(:num_in_progress_rows) { 9 }
    let!(:num_on_hold_rows) { 4 }
    let!(:num_completed_rows) { 5 }

    let!(:vha_regional_assigned_tasks) do
      create_list(:assess_documentation_task, num_assigned_rows, :assigned, assigned_to: regional_office)
    end
    let!(:vha_regional_in_progress_tasks) do
      create_list(:assess_documentation_task, num_in_progress_rows, :in_progress, assigned_to: regional_office)
    end
    let!(:vha_regional_on_hold_tasks) do
      create_list(:assess_documentation_task, num_on_hold_rows, :on_hold, assigned_to: regional_office)
    end
    let!(:vha_regional_completed_tasks) do
      create_list(:assess_documentation_task, num_completed_rows, :completed, assigned_to: regional_office)
    end

    before do
      User.authenticate!(user: regional_office_user)
      regional_office.add_user(regional_office_user)
      regional_office_user.reload
      visit "/organizations/#{regional_office.url}?tab=po_assigned&page=1&sort_by=typeColumn&order=asc"
    end

    scenario "Vha Regional office Queue contains appropriate header" do
      expect(find("h1")).to have_content("#{regional_office.name} cases")
    end

    scenario "Vha Regional Organization Queue Has Assigned, in progress, on hold and completed tabs" do
      expect(page).to have_content assigned_tab_text
      expect(page).to have_content in_progress_tab_text
      expect(page).to have_content on_hold_tab_text
      expect(page).to have_content completed_tab_text
    end

    scenario "tab has the correct column Headings and description text" do
      expect(page).to have_content "Cases assigned to a member of the #{regional_office.name} team:"
      a_normal_tab(assigned_pagination_text)
    end

    scenario "In Progress tab has the correct column Headings and description text" do
      # Navigate to the In Progress Tab
      click_button(in_progress_tab_text)
      expect(page).to have_content "Cases in progress in a #{regional_office.name} team member's queue"
      a_normal_tab(in_progress_pagination_text)
    end

    scenario "On Hold tab has the correct column Headings and description text" do
      # Navigate to the Completed Tab
      click_button(on_hold_tab_text)
      expect(page).to have_content "Cases on hold in a #{regional_office.name} team member's queue"
      a_normal_tab(on_hold_pagination_text)
    end

    scenario "Completed tab has the correct column Headings and description text" do
      # Navigate to the Completed Tab
      click_button(completed_tab_text)
      expect(page).to have_content "Cases completed:"
      a_normal_tab(completed_pagination_text)
    end

    scenario "Assigned tab has the correct number in the tab name and the number of table rows" do
      assigned_tab_button = find("button", text: assigned_tab_text)
      num_table_rows = all("tbody > tr").count
      expect(assigned_tab_button.text).to eq("#{assigned_tab_text} (#{num_assigned_rows})")
      expect(num_table_rows).to eq(num_assigned_rows)
    end

    scenario "In Progress tab has the correct number in the tab name and the number of table rows" do
      in_progress_tab_button = find("button", text: in_progress_tab_text)
      in_progress_tab_button.click
      num_table_rows = all("tbody > tr").count
      expect(in_progress_tab_button.text).to eq("#{in_progress_tab_text} (#{num_in_progress_rows})")
      expect(num_table_rows).to eq(num_in_progress_rows)
    end

    scenario "On hold tab has the correct number in the tab name and the number of table rows" do
      on_hold_tab_button = find("button", text: on_hold_tab_text)
      on_hold_tab_button.click
      num_table_rows = all("tbody > tr").count
      expect(on_hold_tab_button.text).to eq("#{on_hold_tab_text} (#{num_on_hold_rows})")
      expect(num_table_rows).to eq(num_on_hold_rows)
    end

    scenario "Completed tab has the correct number of table rows" do
      # Navigate to the Completed Tab
      click_button(completed_tab_text)
      num_table_rows = all("tbody > tr").count
      expect(num_table_rows).to eq(num_completed_rows)
    end
  end
end
