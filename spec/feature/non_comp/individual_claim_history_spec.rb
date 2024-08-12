# frozen_string_literal: true

require_relative "../../../app/services/claim_change_history/change_history_reporter.rb"
require_relative "../../../app/services/claim_change_history/claim_history_service.rb"
require_relative "../../../app/services/claim_change_history/claim_history_event.rb"
require_relative "../../../app/services/claim_change_history/change_history_filter_parser.rb"
require_relative "../../../app/services/claim_change_history/change_history_event_serializer.rb"

feature "Individual Claim History", :postgres do
  let(:non_comp_org) { VhaBusinessLine.singleton }
  let(:user) { create(:default_user, css_id: "REPORT USER", full_name: "Report User") }
  let(:veteran) { create(:veteran) }

  let!(:task_event) do
    create(:issue_modification_request,
           :with_higher_level_review_with_decision,
           nonrating_issue_category: "Medical and Dental Care Reimbursement")
  end

  # Edited then approved
  let!(:issue_modification_request_modification_edit) do
    request = create(:issue_modification_request,
                     :with_request_issue,
                     :edit_of_request,
                     request_type: "modification",
                     decision_review: task_event.decision_review)
    request.update(status: "approved")
  end

  let!(:issue_modification_request_withdrawal_edit) do
    request = create(:issue_modification_request,
                     :with_request_issue,
                     :edit_of_request,
                     :withdrawal,
                     decision_review: task_event.decision_review)
    request.update(status: "approved")
  end

  let!(:issue_modification_request_addition_edit) do
    request = create(:issue_modification_request,
                     :edit_of_request,
                     decision_review: task_event.decision_review)
    request.update(status: "approved")
  end

  let!(:issue_modification_request_removal_edit) do
    request = create(:issue_modification_request,
                     :with_request_issue,
                     :edit_of_request,
                     request_type: "removal",
                     decision_review: task_event.decision_review)
    request.update(status: "approved")
  end

  # cancelled
  let!(:cancelled_issue_modification_request_modification) do
    create(:issue_modification_request,
           :with_request_issue,
           :cancel_of_request,
           request_type: "modification",
           decision_review: task_event.decision_review)
  end

  let!(:cancelled_issue_modification_request_withdrawal) do
    create(:issue_modification_request,
           :with_request_issue,
           :cancel_of_request,
           :withdrawal,
           decision_review: task_event.decision_review)
  end

  let!(:cancelled_issue_modification_request_addition) do
    create(:issue_modification_request,
           :cancel_of_request,
           decision_review: task_event.decision_review)
  end

  let!(:cancelled_issue_modification_request_removal) do
    create(:issue_modification_request,
           :with_request_issue,
           :cancel_of_request,
           request_type: "removal",
           decision_review: task_event.decision_review)
  end

  # Rejected aka Denied
  let!(:denied_issue_modification_request_modification) do
    request = create(:issue_modification_request,
                     :with_request_issue,
                     request_type: "modification",
                     decision_review: task_event.decision_review)

    request.update(
      status: "denied",
      decision_reason: "Decision for denial"
    )
  end

  let!(:denied_issue_modification_request_withdrawal) do
    request = create(:issue_modification_request,
                     :with_request_issue,
                     :withdrawal,
                     decision_review: task_event.decision_review)

    request.update(
      status: "denied",
      decision_reason: "Decision for denial"
    )
  end

  let!(:denied_issue_modification_request_addition) do
    request = create(:issue_modification_request,
                     decision_review: task_event.decision_review)

    request.update(
      status: "denied",
      decision_reason: "Decision for denial"
    )
  end

  let!(:denied_issue_modification_request_removal) do
    request = create(:issue_modification_request,
                     :with_request_issue,
                     request_type: "removal",
                     decision_review: task_event.decision_review)

    request.update(
      status: "denied",
      decision_reason: "Decision for denial"
    )
  end

  let(:task_id) { task_event.decision_review.tasks.ids[0] }

  let(:task_history_url) { "/decision_reviews/vha/tasks/#{task_id}/history" }
  let(:events) { ClaimHistoryService.new(non_comp_org, task_id: task_id).build_events }

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
    visit task_history_url
  end

  scenario "display the claim history table" do
    number_of_events = events.length

    expect(page).to have_text("Viewing 1-15 of #{number_of_events} total")

    # binding.pry

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 15)
    find("button", text: "2").click
    table_page_two = page.find("tbody")
    expect(table_page_two).to have_selector("tr", count: 4)

    events.each do |event|
      expect(page).to have_text(event.readable_event_type)
    end
  end

  scenario "Approval of request - issue addition" do
    find(".table-icon unselected-filter-icon").click
    find("2-Approval of request - issue addition").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.find('tr[id^="table-row"]')
    expect(table_row).to have_content("Approval of request - issue addition")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Request originated by")

    find("a", "View original request").click
    expect(table_row).to have_content("View original request")

    table_data = table_row.find("td").last
    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Addition request reason:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Approval of request - issue modification" do
    find(".table-icon unselected-filter-icon").click

    find("3-Approval of request - issue modification").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    table_row = table.find("tr", id: "table-row")
    expect(table_row).to have_content("Approval of request - issue addition")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Remove original issue:")
    expect(table_row).to have_content("Request originated by")
    expect(table_row).to have_content("View original request")

    find("a", "View original request").click
    expect(table_row).to have_content("Hide original request")

    table_data = table_row.find("td").last
    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Addition request reason:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Approval of request - issue removal" do
    find(".table-icon unselected-filter-icon").click

    find("4-Approval of request - issue removal").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.find("tr", id: "table-row")
    expect(table_row).to have_content("Approval of request - issue removal")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Request originated by")
    expect(table_row).to have_content("View original request")

    find("a", "View original request").click
    expect(table_row).to have_content("Hide original request")

    table_data = table_row.find("td").last
    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Removal request reason:")

    find("cf-clear-filter-button-wrapper").click

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Approval of request - issue withdrawal" do
    find(".table-icon unselected-filter-icon").click
    find("5-Approval of request - issue withdrawal").click

    table_row = table.find("tr", id: "table-row")
    expect(table_row).to have_content("Approval of request - issue removal")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Request originated by")
    expect(table_row).to have_content("View original request")

    find("a", "View original request").click
    expect(table_row).to have_content("Hide original request")

    table_data = table_row.find("td").last
    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Withdrawal request reason:")
    expect(table_data).to have_content("Withdrawal request date:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Cancellation of request" do
    find(".table-icon unselected-filter-icon").click
    find("Cancellation of request").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 4)

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Edit of request - issue addition" do
    find(".table-icon unselected-filter-icon").click
    find("11-Edit of request - issue addition").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.find("tr", id: "table-row")
    expect(table_row).to have_content("Edit of request - issue addition")

    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("New addition request reason::")

    find("a", "View original request").click
    expect(table_row).to have_content("Hide original request")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Addition request reason:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Edit of request - issue modification" do
    find(".table-icon unselected-filter-icon").click
    find("14-Edit of request - issue withdrawal").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    table_row = table.find("tr", id: "table-row")
    expect(table_row).to have_content("Edit of request - issue withdrawal")

    expect(table_row).to have_content("New withdrawal request reason:")
    expect(table_row).to have_content("New withdrawal request date:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Withdrawal request reason:")
    expect(table_data).to have_content("Withdrawal request date:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Edit of request - issue removal" do
    find(".table-icon unselected-filter-icon").click
    find("13-Edit of request - issue removal").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 2)

    table_row = table.find("tr", id: "table-row")
    expect(table_row).to have_content("Edit of request - issue removal")

    expect(table_row).to have_content("New removal request reason:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Removal request reason:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Edit of request - issue withdrawal" do
    find(".table-icon unselected-filter-icon").click

    find("14-Edit of request - issue withdrawal").click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    table_row = table.find("tr").first
    expect(table_row).to have_content("Edit of request - issue withdrawal")

    expect(table_row).to have_content("New withdrawal request reason:")
    expect(table_row).to have_content("New withdrawal request date:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Withdrawal request reason:")
    expect(table_data).to have_content("Withdrawal request date:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Rejection of request - issue addition" do
    find(".table-icon unselected-filter-icon").click
    find("15-Rejection of request - issue addition").click
    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Addition request reason:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Rejection of request - issue modification" do
    find(".table-icon unselected-filter-icon").click
    find("15-Rejection of request - issue modification").click
    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Current issue type:")
    expect(table_data).to have_content("Current issue description:")
    expect(table_data).to have_content("New issue type:")
    expect(table_data).to have_content("New issue description:")
    expect(table_data).to have_content("New decision date:")
    expect(table_data).to have_content("Modification request reason:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Rejection of request - issue removal" do
    find(".table-icon unselected-filter-icon").click
    find("17-Rejection of request - issue removal").click
    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 2)

    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")

    find("cf-clear-filter-button-wrapper").click
  end

  scenario "Rejection of request - issue withdrawal" do
    find(".table-icon unselected-filter-icon").click
    find("17-Rejection of request - issue withdrawal").click
    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 2)

    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    table_data = table_row.find("td").last

    expect(table_data).to have_content("Benefit type:")
    expect(table_data).to have_content("Issue type:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Issue description:")
    expect(table_data).to have_content("Decision date:")
    expect(table_data).to have_content("Withdrawal request reason:")
    expect(table_data).to have_content("Withdrawal request date:")

    find("cf-clear-filter-button-wrapper").click
  end
end
