# frozen_string_literal: true

feature "attorney checkout flow when appeal has withdrawn request issues", :all_dbs do
  it "displays withdrawn status on case details page" do
    appeal = create(:appeal)
    judge = create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge")
    attorney = create(:user)
    User.authenticate!(user: attorney)
    create_ama_attorney_task(appeal, judge, attorney)
    create_withdrawn_request_issue(appeal)
    create_active_request_issue(appeal)
    visit "/queue/appeals/#{appeal.uuid}"
    expect(page).to have_content("Disposition: Withdrawn", wait: 10)

    select_decision_ready_for_review
    if !find("#no_special_issues", visible: false).checked?
      find("label", text: "No Special Issues").click
    end
    click_on "Continue"
    click_add_decision_on_first_issue

    expect_disposition_dropdown_to_be_preselected_with_withdrawn

    fill_in_description_field_and_save_the_decision_issue
    click_add_decision_on_second_issue
    select_allowed_disposition
    fill_in_description_field_and_save_the_decision_issue
    click_on "Continue"
    fill_in_document_id
    submit_draft_decision

    expect(page).to have_current_path("/queue")

    visit_case_details_page_after_attorney_checkout(appeal)

    expect_withdrawn_request_issue_to_be_displayed_along_with_its_decision_issue
  end

  def select_decision_ready_for_review
    click_dropdown(index: 0)
  end

  def click_add_decision_on_first_issue
    all("button", text: "+ Add decision", count: 2)[0].click
  end

  def expect_disposition_dropdown_to_be_preselected_with_withdrawn
    expect(page).to have_content("Withdrawn")
  end

  def fill_in_description_field_and_save_the_decision_issue
    fill_in "Text Box", with: "test description"
    click_on "Save"
  end

  def click_add_decision_on_second_issue
    all("button", text: "+ Add decision", count: 2)[1].click
  end

  def select_allowed_disposition
    find(".cf-select__control", text: "Select disposition").click
    find("div", class: "cf-select__option", text: "Allowed").click
  end

  def fill_in_document_id
    fill_in "document_id", with: "12345678.123"
  end

  def submit_draft_decision
    click_on "Continue"
  end

  def visit_case_details_page_after_attorney_checkout(appeal)
    visit "/queue/appeals/#{appeal.reload.uuid}"
  end

  def expect_withdrawn_request_issue_to_be_displayed_along_with_its_decision_issue
    expect(page).to have_content "Tinnitus"
    expect(page).to have_content("Withdrawn")
  end

  def create_ama_attorney_task(appeal, judge, attorney)
    create(
      :ama_attorney_task,
      :in_progress,
      assigned_to: attorney,
      assigned_by: judge,
      parent: parent_task(appeal, judge)
    )
  end

  def parent_task(appeal, judge)
    create(
      :ama_judge_decision_review_task,
      assigned_to: judge,
      parent: create(:root_task, appeal: appeal)
    )
  end

  def create_withdrawn_request_issue(appeal)
    create(
      :request_issue,
      decision_review: appeal,
      contested_issue_description: "Tinnitus",
      closed_at: Time.zone.now,
      closed_status: "withdrawn"
    )
  end

  def create_active_request_issue(appeal)
    create(:request_issue, decision_review: appeal, contested_issue_description: "Back pain")
  end
end
