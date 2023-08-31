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
    let(:num_assigned_rows) { 3 }
    let(:num_in_progress_rows) { 9 }
    let(:num_on_hold_rows) { 4 }
    let(:num_completed_rows) { 5 }

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

    scenario "Vha Regional Office queue task tabs", :aggregate_failures do
      step "contains appropriate header and tabs" do
        expect(find("h1")).to have_content("#{regional_office.name} cases")
        expect(page).to have_content assigned_tab_text
        expect(page).to have_content in_progress_tab_text
        expect(page).to have_content on_hold_tab_text
        expect(page).to have_content completed_tab_text
      end

      step "Assigned tab" do
        assigned_tab_button = find("button", text: assigned_tab_text)
        expect(page).to have_content "Cases assigned to a member of the #{regional_office.name} team:"
        a_normal_tab(assigned_pagination_text)
        num_table_rows = all("tbody > tr").count
        expect(assigned_tab_button.text).to eq("#{assigned_tab_text} (#{num_assigned_rows})")
        expect(num_table_rows).to eq(num_assigned_rows)
      end

      step "In Progress tab" do
        # Navigate to the In Progress Tab
        in_progress_tab_button = find("button", text: in_progress_tab_text)
        click_button(in_progress_tab_text)
        expect(page).to have_content "Cases in progress in a #{regional_office.name} team member's queue"
        a_normal_tab(in_progress_pagination_text)

        num_table_rows = all("tbody > tr").count
        expect(in_progress_tab_button.text).to eq("#{in_progress_tab_text} (#{num_in_progress_rows})")
        expect(num_table_rows).to eq(num_in_progress_rows)
      end

      step "On Hold tab" do
        on_hold_tab_button = find("button", text: on_hold_tab_text)
        click_button(on_hold_tab_text)
        expect(page).to have_content "Cases on hold in a #{regional_office.name} team member's queue"
        a_normal_tab(on_hold_pagination_text)
        num_table_rows = all("tbody > tr").count
        expect(on_hold_tab_button.text).to eq("#{on_hold_tab_text} (#{num_on_hold_rows})")
        expect(num_table_rows).to eq(num_on_hold_rows)
      end

      step "Completed tab" do
        # Navigate to the Completed Tab
        click_button(completed_tab_text)
        expect(page).to have_content "Cases completed:"
        a_normal_tab(completed_pagination_text)
        num_table_rows = all("tbody > tr").count
        expect(num_table_rows).to eq(num_completed_rows)
      end
    end
  end

  context "VhaRegional Queue can send back task to Program office" do
    let(:visn_org) { create(:vha_regional_office) }
    let(:visn_user) { create(:user) }
    before do
      User.authenticate!(user: visn_user)
    end

    let(:visn_in_progress) do
      create(
        :assess_documentation_task_predocket,
        :in_progress,
        assigned_to: visn_org
      )
    end
    let(:visn_task_on_hold) do
      create(
        :assess_documentation_task_predocket,
        :on_hold,
        assigned_to: visn_org
      )
    end
    let(:visn_task) do
      create(
        :assess_documentation_task_predocket,
        :assigned,
        assigned_to: visn_org
      )
    end

    before do
      visn_org.add_user(visn_user)
    end

    # rubocop:disable Metrics/AbcSize
    def return_to_po_office(tab_name)
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find(
        "div",
        class: "cf-select__option",
        text: Constants.TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.label
      ).click
      expect(page).to have_content(COPY::VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE_MODAL_TITLE)
      expect(page).to have_content(COPY::VHA_CANCEL_TASK_INSTRUCTIONS_LABEL)
      fill_in("taskInstructions", with: "Testing this Cancellation flow")
      find("button", class: "usa-button", text: COPY::MODAL_RETURN_BUTTON).click
      expect(page).to have_current_path("#{visn_org.path}?tab=#{tab_name}&page=1&sort_by=typeColumn&order=asc")
      expect(page).to have_content(COPY::VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE_CONFIRMATION_TITLE)
      expect(page).to have_content(COPY::VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE_CONFIRMATION_DETAIL)
    end
    # rubocop:enable Metrics/AbcSize

    it "Assigned task can be sent to program office" do
      reload_case_detail_page(visn_task.appeal.uuid)
      return_to_po_office("po_assigned")
      visn_task.reload
      expect(visn_task.status).to eq "cancelled"
    end

    it "In Progress task can be sent to program office" do
      reload_case_detail_page(visn_in_progress.appeal.uuid)
      return_to_po_office("po_assigned")
      visn_in_progress.reload
      expect(visn_in_progress.status).to eq "cancelled"
    end

    it "On Hold task can be sent to program office" do
      reload_case_detail_page(visn_task_on_hold.appeal.uuid)
      return_to_po_office("po_assigned")
      visn_task_on_hold.reload
      expect(visn_task_on_hold.status).to eq "cancelled"
    end
  end
end
