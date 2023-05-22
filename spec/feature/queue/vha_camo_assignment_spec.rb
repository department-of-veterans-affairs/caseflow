# frozen_string_literal: true

RSpec.feature "CAMO assignment to program office", :all_dbs do
  let(:camo_org) { VhaCamo.singleton }
  let(:vha_po_org) { VhaProgramOffice.create!(name: "Vha Program Office", url: "vha-po") }
  let(:camo_user) { create(:user, full_name: "Camo User", css_id: "CAMOUSER") }
  let(:vha_po_user) { create(:user, full_name: "PO User", css_id: "VHAPOUSER") }
  let!(:appeals) do
    Array.new(5) do
      create(
        :vha_document_search_task,
        :assigned,
        assigned_to: camo_org,
        appeal: create(:appeal)
      )
    end.map(&:appeal)
  end

  let!(:issue_types) do
    [
      "Eligibility for Dental Treatment",
      "Spina Bifida Treatment (Non-Compensation)",
      "Beneficiary Travel",
      "Caregiver | Eligibility",
      "Clothing Allowance"
    ]
  end

  let!(:appeal_request_issues) do
    request_issues = issue_types.map do |issue_type|
      create(:request_issue, :nonrating, nonrating_issue_category: issue_type)
    end

    appeals.each_with_index do |appeal, index|
      appeal.request_issues << request_issues[index]
      appeal.save
    end
    request_issues
  end

  let(:column_heading_names) do
    [
      "Select", "Case Details", "Types", "Docket", "Issues", "Issue Type", "Days Waiting", "Veteran Documents"
    ]
  end

  before do
    FeatureToggle.enable!(:vha_predocket_workflow)
    camo_org.add_user(camo_user)
    vha_po_org.add_user(vha_po_user)
    User.authenticate!(user: camo_user)
  end

  after do
    FeatureToggle.disable!(:vha_predocket_workflow)
  end

  context "CAMO user can load assign page and relevant information" do
    let(:task_first) { VhaDocumentSearchTask.first }
    let(:task_last) { VhaDocumentSearchTask.last }
    scenario "can visit 'Assign' view and assign cases" do
      step "visit assign queue" do
        visit "/queue/#{camo_user.css_id}/assign?role=camo"
        expect(page).to have_content("Assign 5 Cases")
        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(5)
      end

      step "page errors when cases aren't selected" do
        safe_click ".cf-select"
        click_dropdown(text: vha_po_org.name)

        click_on "Assign 0 cases"
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_TASK_TITLE)
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_TASK_DETAIL)
      end

      step "page errors when a program office isn't selected" do
        visit "/queue/#{camo_user.css_id}/assign?role=camo"
        scroll_to(".usa-table-borderless")
        page.find(:css, "input[name='#{task_first.id}']", visible: false).execute_script("this.click()")
        page.find(:css, "input[name='#{task_last.id}']", visible: false).execute_script("this.click()")

        click_on "Assign 2 cases"
        expect(page).to have_content(COPY::ASSIGN_WIDGET_NO_ASSIGNEE_TITLE)
        expect(page).to have_content(COPY::CAMO_ASSIGN_WIDGET_NO_ASSIGNEE_DETAIL)
      end

      step "cases are assignable when a program office and tasks are selected" do
        safe_click ".cf-select"
        click_dropdown(text: vha_po_org.name)

        click_on "Assign 2 cases"
        expect(page).to have_content("Assigned 2 tasks to #{vha_po_org.name}")
        expect(page).to have_content("Assign 3 Cases")
        case_rows = page.find_all("tr[id^='table-row-']")
        expect(case_rows.length).to eq(3)
      end
    end

    scenario "It has the correct body text and column headings" do
      visit "/queue/#{camo_user.css_id}/assign?role=camo"
      html_table_headings = all("th").map(&:text).reject(&:empty?).compact
      expect(page).to have_content "Cases to Assign"
      expect(html_table_headings).to eq(column_heading_names)
    end
  end

  context "CAMO User can sort and filter tasks on the CAMO bulk assignment page" do
    # let(:filter_label_text) { "Issue Type" }
    let(:filter_column_label_text) { "Issue Type" }
    scenario "CAMO User can sort by issue types" do
      visit "/queue/#{camo_user.css_id}/assign?role=camo"

      # Sort by issue type
      find("[aria-label='Sort by Issue Type']").click

      # Check order and it should be sorted in descending order
      table_rows = all("table tbody tr")
      table_rows.each_with_index do |row, index|
        expect(row).to have_text(issue_types.sort.reverse[index])
      end

      # Click the issue type sort again
      find("[aria-label='Sort by Issue Type']").click

      # Check order and it should be in ascending order
      table_rows = all("table tbody tr")
      table_rows.each_with_index do |row, index|
        expect(row).to have_text(issue_types.sort[index])
      end
    end

    scenario "CAMO User can filter by issue types" do
      visit "/queue/#{camo_user.css_id}/assign?role=camo"

      # Verify Spina Bifida is present on the page
      expect(page).to have_content("Spina Bifida Treatment (Non-Compensation)")

      # Click the issue type filter icon
      find("[aria-label='Filter by issue type']").click

      # Check that all filter counts are there in alphanumerically sorted order
      issue_types.sort.each do |issue_type|
        expect(page).to have_content("#{issue_type} (1)")
      end

      # Filter by Caregiver | Eligibility
      find("label", text: "Caregiver | Eligibility").click
      expect(page).to have_content("Filtering by: #{filter_column_label_text} (1)")
      expect(page).to have_content("Caregiver | Eligibility")
      expect(page).to_not have_content("Beneficiary Travel")
      expect(page).to_not have_content("Spina Bifida Treatment (Non-Compensation)")

      # Clear filter and check if all the data is there again
      find(".cf-clear-filters-link").click

      expect(page).to_not have_content("Filtering by: #{filter_column_label_text}")
      expect(page).to have_content("Spina Bifida Treatment (Non-Compensation)")
      expect(page).to have_content("Caregiver | Eligibility")
      expect(page).to have_content("Beneficiary Travel")
    end
  end
end
