# frozen_string_literal: true

feature "Updating Document ID", :all_dbs do
  context "AMA case review" do
    it "only allows assigner and assignee to edit document ID and validates ID format" do
      attorney = create_ama_case_review

      User.authenticate!(user: attorney)
      visit("/queue/appeals/#{Appeal.last.external_id}")

      expect(page).to have_content "DECISION DOCUMENT ID"
      within "#document-id" do
        click_button "Edit"
      end

      enter_invalid_decision_document_id

      expect(page).to have_content "Document ID of type Draft Decision must be in one of these formats:"
      expect(page).to have_content "12345678.1234"

      enter_valid_decision_document_id

      expect(page).to have_content "Document Id Saved!"
      expect(page).to have_content "11111-22334455"

      switch_to_user_not_associated_with_case_and_visit_ama_appeals_page

      within "#document-id" do
        expect(page).to_not have_button "Edit"
      end

      judge = User.find_by(full_name: "Aaron Judge")
      switch_to_judge_associated_with_case_and_visit_ama_appeals_page(judge)

      within "#document-id" do
        expect(page).to have_button "Edit"
      end
    end
  end

  context "Legacy VHA case review" do
    it "only allows assigner and assignee to edit document ID and validates ID format" do
      judge = create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge")
      create(:staff, :judge_role, sdomainid: judge.css_id)
      attorney = create_legacy_case_review
      appeal = LegacyAppeal.last

      User.authenticate!(user: attorney)
      create_legacy_attorney_case_review_in_browser(appeal)
      visit("/queue/appeals/#{appeal.vacols_id}")

      expect(page).to have_content "DECISION DOCUMENT ID"
      within "#document-id" do
        click_button "Edit"
      end

      enter_invalid_vha_document_id

      expect(page).to have_content "VHA Document IDs must be in one of these formats:"

      enter_valid_vha_document_id

      expect(page).to have_content "Document Id Saved!"
      expect(page).to have_content "V1234567.321"

      reload_page_to_verify_document_id_was_updated_in_vacols

      expect(page).to have_content "V1234567.321"

      switch_to_user_not_associated_with_case_and_visit_legacy_appeals_page

      within "#document-id" do
        expect(page).to_not have_button "Edit"
      end

      switch_to_judge_associated_with_case_and_visit_legacy_appeals_page(judge)

      within "#document-id" do
        expect(page).to have_button "Edit"
      end
    end
  end

  def create_ama_case_review
    judge = create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge")
    create(:staff, :judge_role, sdomainid: judge.css_id)
    appeal = create(:appeal)
    attorney = create(:user)
    root_task = create(:root_task, appeal: appeal, assigned_to: attorney)
    attorney_task = create(
      :ama_attorney_task,
      appeal: appeal,
      parent: root_task,
      assigned_to: attorney,
      closed_at: Time.zone.now - 4.days
    )
    attorney_task.update!(status: Constants.TASK_STATUSES.completed)
    create(
      :attorney_case_review,
      task_id: attorney_task.id,
      attorney: attorney,
      reviewing_judge_id: judge.id,
      document_id: "12345678.1234"
    )
    attorney
  end

  def enter_invalid_decision_document_id
    fill_in "Decision Document ID", with: "123.123"
    click_button "Save"
  end

  def enter_valid_decision_document_id
    fill_in "Decision Document ID", with: "11111-22334455"
    click_button "Save"
  end

  def switch_to_user_not_associated_with_case_and_visit_ama_appeals_page
    user = create(:user)
    User.authenticate!(user: user)
    visit("/queue/appeals/#{Appeal.last.external_id}")
  end

  def switch_to_judge_associated_with_case_and_visit_ama_appeals_page(judge)
    User.authenticate!(user: judge)
    visit("/queue/appeals/#{Appeal.last.external_id}")
    expect(page).to have_content "DECISION DOCUMENT ID"
  end

  def create_legacy_case_review
    attorney = create(:user)
    create(
      :legacy_appeal,
      :with_veteran,
      vacols_case: create(
        :case,
        :assigned,
        user: attorney,
        case_issues: [create(:case_issue)]
      )
    )
    attorney
  end

  def create_legacy_attorney_case_review_in_browser(appeal)
    visit "/queue"
    click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
    click_dropdown(index: 1)
    click_label("omo-type_OMO - VHA")
    fill_in "document_id", with: "V1234567.1234"
    fill_in "notes", with: "test"
    safe_click("#select-judge")
    click_dropdown(index: 0)
    click_on "Continue"
  end

  def enter_invalid_vha_document_id
    fill_in "Decision Document ID", with: "123.123"
    click_button "Save"
  end

  def enter_valid_vha_document_id
    fill_in "Decision Document ID", with: "V1234567.321"
    click_button "Save"
  end

  def reload_page_to_verify_document_id_was_updated_in_vacols
    visit("/queue/appeals/#{LegacyAppeal.last.vacols_id}")
  end

  def switch_to_user_not_associated_with_case_and_visit_legacy_appeals_page
    user = create(:user)
    User.authenticate!(user: user)
    visit("/queue/appeals/#{LegacyAppeal.last.vacols_id}")
    expect(page).to have_content "DECISION DOCUMENT ID"
  end

  def switch_to_judge_associated_with_case_and_visit_legacy_appeals_page(judge)
    User.authenticate!(user: judge)
    visit("/queue/appeals/#{LegacyAppeal.last.vacols_id}")
    expect(page).to have_content "DECISION DOCUMENT ID"
  end
end
