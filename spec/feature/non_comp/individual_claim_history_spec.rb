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

  let!(:cancelled_claim) do
    create(:supplemental_claim, :with_vha_issue, :with_update_users)
  end

  let!(:claim_closed) do
    create(:higher_level_review_vha_task_with_decision)
  end

  let(:task_id) { task_event.decision_review.tasks.ids[0] }

  let(:task_history_url) { "/decision_reviews/vha/tasks/#{task_id}/history" }
  let(:events) { ClaimHistoryService.new(non_comp_org, task_id: task_id).build_events }

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)

    cancelled_claim.establish!
    cancelled_claim.request_issues.update(closed_status: "withdrawn", closed_at: Time.zone.now)
    cancelled_claim.tasks.update(status: "cancelled")
    cancelled_claim.reload

    visit task_history_url
  end

  scenario "To have all event types" do
    event_types = events.map(&:readable_event_type).uniq.sort!
    button = page.all("div.cf-pagination-pages button", text: "Next")[0]

    events_found = []
    loop do
      event_types.each do |event|
        if page.has_text?(event)
          events_found << event unless events_found.include?(event)
        end
      end

      break if events_found.sort == event_types.sort

      break if button.disabled?

      button.click
    end

    expect(events_found.count).to eq(event_types.count)
  end

  scenario "display the claim history table" do
    expect(page).to have_text("Viewing 1-15 of #{events.length} total")

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 15)

    find("button", text: "2", match: :first).click
    table_page_two = page.find("div", class: "cf-table-wrapper")
    expect(table_page_two).to have_text("Viewing 16-30 of #{events.length} total")

    find("button", text: "3", match: :first).click
    table_page_three = page.find("div", class: "cf-table-wrapper")
    expect(table_page_three).to have_text("Viewing 31-45 of #{events.length} total")

    find("button", text: "4", match: :first).click
    table_page_four = page.find("div", class: "cf-table-wrapper")
    expect(table_page_four).to have_text("Viewing 46-48 of #{events.length} total")
  end

  scenario "Approval of request - issue addition" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click

    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Approval of request - issue addition (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Approval of request - issue addition")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Request originated by:")

    expect(table_row).to have_content("View original request")
    table_row.first("a", text: "View original request").click

    expect(table_row).to have_content("Hide original request")
    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Addition request reason:")
  end

  scenario "Approval of request - issue modification" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click

    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Approval of request - issue modification (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Approval of request - issue modification")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Remove original issue:")
    expect(table_row).to have_content("Request originated by")
    expect(table_row).to have_content("View original request")

    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Current issue type:")
    expect(table_row).to have_content("Current issue description:")
    expect(table_row).to have_content("Current decision date:")
    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("Modification request reason:")
  end

  scenario "Approval of request - issue removal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Approval of request - issue removal (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Approval of request - issue removal")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Request originated by")
    expect(table_row).to have_content("View original request")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Removal request reason:")
  end

  scenario "Approval of request - issue withdrawal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Approval of request - issue withdrawal (1)", match: :prefer_exact).click

    table = page.find("tbody")
    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Approval of request - issue withdrawal")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Request originated by")
    expect(table_row).to have_content("View original request")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Withdrawal request reason:")
    expect(table_row).to have_content("Withdrawal request date:")
  end

  scenario "Cancellation of request" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Cancellation of request", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 4)
  end

  scenario "Edit of request - issue addition" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Edit of request - issue addition (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first('tr[id^="table-row"]')

    expect(table_row).to have_content("Edit of request - issue addition")
    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("New addition request reason:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Addition request reason:")
  end

  scenario "Edit of request - issue modification" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Edit of request - issue modification (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Edit of request - issue modification")

    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("New modification request reason:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Current issue type:")
    expect(table_row).to have_content("Current issue description:")
    expect(table_row).to have_content("Current decision date:")
    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("Modification request reason:")
  end

  scenario "Edit of request - issue removal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Edit of request - issue removal (4)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 4)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Edit of request - issue removal")
    expect(table_row).to have_content("New removal request reason:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Removal request reason:")
  end

  scenario "Edit of request - issue withdrawal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Edit of request - issue withdrawal (4)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 4)

    table_row = table.first("tr")
    expect(table_row).to have_content("Edit of request - issue withdrawal")
    expect(table_row).to have_content("New withdrawal request reason:")
    expect(table_row).to have_content("New withdrawal request date:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Withdrawal request reason:")
    expect(table_row).to have_content("Withdrawal request date:")
  end

  scenario "Rejection of request - issue addition" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Rejection of request - issue addition (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first("tr")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Addition request reason:")
  end

  scenario "Rejection of request - issue modification" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Rejection of request - issue modification (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first("tr")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Current issue type:")
    expect(table_row).to have_content("Current issue description:")
    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("Modification request reason:")
  end

  scenario "Rejection of request - issue removal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Rejection of request - issue removal (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first("tr")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Decision date:")
  end

  scenario "Rejection of request - issue withdrawal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Rejection of request - issue withdrawal (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first("tr")
    expect(table_row).to have_content("Request decision:")
    expect(table_row).to have_content("Reason for rejection:")
    expect(table_row).to have_content("Request originated by:")

    expect(table_row).to have_content("View original request")
    first("a", text: "View original request").click
    expect(table_row).to have_content("Hide original request")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Withdrawal request reason:")
    expect(table_row).to have_content("Withdrawal request date:")
  end

  scenario "Added issue" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Added issue", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 10)

    table_row = table.first("tr")
    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
  end

  scenario "Requested issue addition" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Requested issue addition (4)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 4)

    table_row = table.first("tr")
    expect(table_row).to have_content("Requested issue addition")
    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Addition request reason:")
  end

  scenario "Requested issue modification" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click

    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Requested issue modification (3)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Requested issue modification")
    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Current issue type:")
    expect(table_row).to have_content("Current issue description:")
    expect(table_row).to have_content("Current decision date:")
    expect(table_row).to have_content("New issue type:")
    expect(table_row).to have_content("New issue description:")
    expect(table_row).to have_content("New decision date:")
    expect(table_row).to have_content("Modification request reason:")
  end

  scenario "Requested issue removal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Requested issue removal (3)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    table_row = table.first('tr[id^="table-row"]')
    expect(table_row).to have_content("Requested issue removal")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Removal request reason:")
  end

  scenario "Requested issue withdrawal" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Requested issue withdrawal (3)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 3)

    table_row = table.first("tr")
    expect(table_row).to have_content("Requested issue withdrawal")

    expect(table_row).to have_content("Benefit type:")
    expect(table_row).to have_content("Issue type:")
    expect(table_row).to have_content("Issue description:")
    expect(table_row).to have_content("Decision date:")
    expect(table_row).to have_content("Withdrawal request reason:")
    expect(table_row).to have_content("Withdrawal request date:")
  end

  scenario "claim status - Pending" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Claim status - Pending (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first("tr")
    expect(table_row).to have_content("Claim status - Pending")
    expect(table_row).to have_content("Claim cannot be processed until VHA admin reviews pending requests.")
  end

  scenario "Claim created" do
    sort = find("[aria-label='Filter by Activity']").click
    sort.click
    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: "Claim created (1)", match: :prefer_exact).click

    table = page.find("tbody")
    expect(table).to have_selector("tr", count: 1)

    table_row = table.first("tr")
    expect(table_row).to have_content("Claim created")
    expect(table_row).to have_content("Claim created.")
  end

  context "should do expected details to show claim close for a claim close" do
    before { visit "/decision_reviews/vha/tasks/#{claim_closed.id}/history" }

    it "Claim closed" do
      sort = find("[aria-label='Filter by Activity']").click
      sort.click
      dropdown_filter = page.find(class: "cf-dropdown-filter")
      dropdown_filter.find("label", text: "Claim closed (1)", match: :prefer_exact).click

      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 1)

      table_row = table.first("tr")
      expect(table_row).to have_content("Claim closed")
      expect(table_row).to have_content("Claim decision date:")
    end
  end

  context "should do expected details to show claim closed when cancelled" do
    before { visit "/decision_reviews/vha/tasks/#{cancelled_claim.tasks[0].id}/history" }

    it "Claim Cancelled" do
      sort = find("[aria-label='Filter by Activity']").click
      sort.click
      dropdown_filter = page.find(class: "cf-dropdown-filter")

      dropdown_filter.find("label", text: "Claim closed (1)", match: :prefer_exact).click
      table = page.find("tbody")
      expect(table).to have_selector("tr", count: 1)

      table_row = table.first("tr")
      expect(table_row).to have_content("Claim closed")
      expect(table_row).to have_content("Claim cancelled.")
    end
  end
end
