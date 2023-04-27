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
    end
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
  end
end
