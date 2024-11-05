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

  before do
    User.stub = user
    non_comp_org.add_user(user)
    OrganizationsUser.make_user_admin(user, non_comp_org)
  end

  def click_filter_option(filter_text)
    sort = find("[aria-label='Filter by Activity']")
    sort.click

    dropdown_filter = page.find(class: "cf-dropdown-filter")
    dropdown_filter.find("label", text: filter_text, match: :prefer_exact).click
  end

  def clear_filter_option(filter_text)
    sort = find("[aria-label='Filter by Activity. Filtering by #{filter_text}']")
    sort.click

    clear_button_filter = page.find(class: "cf-clear-filter-button-wrapper", wait: 10)
    clear_button_filter.click
  end

  describe "Check for event hitsoty activity dynamic labels" do
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
      request
    end

    let!(:issue_modification_request_withdrawal_edit) do
      request = create(:issue_modification_request,
                       :with_request_issue,
                       :edit_of_request,
                       :withdrawal,
                       decision_review: task_event.decision_review)
      request.update(status: "approved")
      request
    end

    let!(:issue_modification_request_addition_edit) do
      request = create(:issue_modification_request,
                       :edit_of_request,
                       decision_review: task_event.decision_review)
      request.update(status: "approved")
      request
    end

    let!(:issue_modification_request_removal_edit) do
      request = create(:issue_modification_request,
                       :with_request_issue,
                       :edit_of_request,
                       request_type: "removal",
                       decision_review: task_event.decision_review)
      request.update(status: "approved")
      request
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
      request
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
      request
    end

    let!(:denied_issue_modification_request_addition) do
      request = create(:issue_modification_request,
                       decision_review: task_event.decision_review)

      request.update(
        status: "denied",
        decision_reason: "Decision for denial"
      )
      request
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
      request
    end

    let!(:claim_closed) do
      create(:higher_level_review_vha_task_with_decision)
    end

    let(:task_id) { task_event.decision_review.tasks.ids[0] }

    let(:task_history_url) { "/decision_reviews/vha/tasks/#{task_id}/history" }
    let(:events) { ClaimHistoryService.new(non_comp_org, task_id: task_id).build_events }

    before do
      visit task_history_url
    end

    let(:event_types) { events.map(&:readable_event_type).uniq.sort! }

    context "Testing all Event Types" do
      it "Filtering each event and verifiying row attributes" do
        step "display the claim history table count" do
          expect(page).to have_text("Viewing 1-15 of #{events.length} total")

          click_filter_option("Approval of request - issue addition (1)")
          expect(event_types.include?("Approval of request - issue addition")).to be_truthy

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
          clear_filter_option("Approval of request - issue addition")
        end

        step "Checking Approval of request - issue modification" do
          click_filter_option("Approval of request - issue modification (1)")
          expect(event_types.include?("Approval of request - issue modification")).to be_truthy

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
          clear_filter_option("Approval of request - issue modification")
        end

        step "Checking Approval of request - issue removal" do
          click_filter_option("Approval of request - issue removal (1)")
          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 1)
          expect(event_types.include?("Approval of request - issue removal")).to be_truthy

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
          clear_filter_option("Approval of request - issue removal")
        end

        step "Checking Approval of request - issue withdrawal" do
          click_filter_option("Approval of request - issue withdrawal (1)")
          expect(event_types.include?("Approval of request - issue withdrawal")).to be_truthy

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
          clear_filter_option("Approval of request - issue withdrawal")
        end

        step "Checking Cancellation of request" do
          click_filter_option("Cancellation of request")
          expect(event_types.include?("Cancellation of request")).to be_truthy
          table = page.find("tbody")

          expect(table).to have_selector("tr", count: 4)
          clear_filter_option("Cancellation of request")
        end

        step "Checking Edit of request - issue addition" do
          click_filter_option("Edit of request - issue addition (1)")
          expect(event_types.include?("Edit of request - issue addition")).to be_truthy

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
          clear_filter_option("Edit of request - issue addition")
        end

        step "Checking Edit of request - issue modification" do
          click_filter_option("Edit of request - issue modification (1)")
          expect(event_types.include?("Edit of request - issue modification")).to be_truthy
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

          clear_filter_option("Edit of request - issue modification")
        end

        step "Checking Edit of request - issue removal" do
          click_filter_option("Edit of request - issue removal (4)")
          expect(event_types.include?("Edit of request - issue removal")).to be_truthy

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
          clear_filter_option("Edit of request - issue removal")
        end

        step "Checking Edit of request - issue withdrawal" do
          click_filter_option("Edit of request - issue withdrawal (4)")
          expect(event_types.include?("Edit of request - issue withdrawal")).to be_truthy

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
          clear_filter_option("Edit of request - issue withdrawal")
        end

        step "Checking Rejection of request - issue addition" do
          click_filter_option("Rejection of request - issue addition (1)")
          expect(event_types.include?("Rejection of request - issue addition")).to be_truthy

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

          clear_filter_option("Rejection of request - issue addition")
        end

        step "Checking Rejection of request - issue modification" do
          click_filter_option("Rejection of request - issue modification (1)")
          expect(event_types.include?("Rejection of request - issue modification")).to be_truthy

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

          clear_filter_option("Rejection of request - issue modification")
        end

        step "Checking Rejection of request - issue removal" do
          click_filter_option("Rejection of request - issue removal (1)")
          expect(event_types.include?("Rejection of request - issue removal")).to be_truthy

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

          clear_filter_option("Rejection of request - issue removal")
        end

        step "Checking Rejection of request - issue withdrawal" do
          click_filter_option("Rejection of request - issue withdrawal (1)")
          expect(event_types.include?("Rejection of request - issue withdrawal")).to be_truthy

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

          clear_filter_option("Rejection of request - issue withdrawal")
        end

        step "Checking Added issue" do
          click_filter_option("Added issue")
          expect(event_types.include?("Added issue")).to be_truthy

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 10)

          table_row = table.first("tr")
          expect(table_row).to have_content("Benefit type:")
          expect(table_row).to have_content("Issue type:")
          expect(table_row).to have_content("Issue description:")
          expect(table_row).to have_content("Decision date:")

          clear_filter_option("Added issue")
        end

        step "checking Requested issue addition" do
          click_filter_option("Requested issue addition (4)")
          expect(event_types.include?("Requested issue addition")).to be_truthy

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 4)

          table_row = table.first("tr")
          expect(table_row).to have_content("Requested issue addition")
          expect(table_row).to have_content("Benefit type:")
          expect(table_row).to have_content("Issue type:")
          expect(table_row).to have_content("Issue description:")
          expect(table_row).to have_content("Decision date:")
          expect(table_row).to have_content("Addition request reason:")

          clear_filter_option("Requested issue addition")
        end

        step "Checking Requested issue modification" do
          click_filter_option("Requested issue modification (3)")
          expect(event_types.include?("Requested issue modification")).to be_truthy

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

          clear_filter_option("Requested issue modification")
        end

        step "Checking Requested issue removal" do
          click_filter_option("Requested issue removal (3)")
          expect(event_types.include?("Requested issue removal")).to be_truthy

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 3)

          table_row = table.first('tr[id^="table-row"]')
          expect(table_row).to have_content("Requested issue removal")

          expect(table_row).to have_content("Benefit type:")
          expect(table_row).to have_content("Issue type:")
          expect(table_row).to have_content("Issue description:")
          expect(table_row).to have_content("Decision date:")
          expect(table_row).to have_content("Removal request reason:")

          clear_filter_option("Requested issue removal")
        end

        step "Checking Requested issue withdrawal" do
          click_filter_option("Requested issue withdrawal (3)")
          expect(event_types.include?("Requested issue withdrawal")).to be_truthy

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

          clear_filter_option("Requested issue withdrawal")
        end

        step "Checking Claim status - Pending" do
          click_filter_option("Claim status - Pending (1)")
          expect(event_types.include?("Claim status - Pending")).to be_truthy

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 1)

          table_row = table.first("tr")
          expect(table_row).to have_content("Claim status - Pending")
          expect(table_row).to have_content("Claim cannot be processed until VHA admin reviews pending requests.")

          clear_filter_option("Claim status - Pending")
        end

        step "Checking Claim created" do
          click_filter_option("Claim created (1)")
          expect(event_types.include?("Claim created")).to be_truthy

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 1)

          table_row = table.first("tr")
          expect(table_row).to have_content("Claim created")
          expect(table_row).to have_content("Claim created.")
        end
      end
    end

    context "should do expected details to show claim close for a claim close" do
      before { visit "/decision_reviews/vha/tasks/#{claim_closed.id}/history" }

      it "Claim closed" do
        click_filter_option("Claim closed (1)")

        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)

        table_row = table.first("tr")
        expect(table_row).to have_content("Claim closed")
        expect(table_row).to have_content("Claim decision date:")
      end
    end
  end

  describe "check for dynamic data coming in" do
    let!(:task_event_two) do
      create(:issue_modification_request,
             :with_higher_level_review_with_decision,
             nonrating_issue_category: "Medical and Dental Care Reimbursement")
    end
    let(:task_event_two_id) { task_event_two.decision_review.tasks.ids[0] }

    let!(:approved_modification_edit) do
      create(:issue_modification_request,
             request_type: "modification",
             decision_review: task_event_two.decision_review,
             request_issue: task_event_two.decision_review.request_issues.first,
             request_reason: "Initial request reason",
             decision_date: 2.days.ago)
    end

    let!(:cancelled_issue_modification_request_modification) do
      create(:issue_modification_request,
             :with_request_issue,
             :cancel_of_request,
             request_type: "modification",
             decision_review: task_event_two.decision_review)
    end

    let!(:denied_issue_modification_request_modification) do
      request = create(:issue_modification_request,
                       :with_request_issue,
                       request_type: "modification",
                       decision_review: task_event_two.decision_review)

      request.update(
        status: "denied",
        decision_reason: "Decision for approval"
      )
      request
    end

    let(:events) { ClaimHistoryService.new(non_comp_org, task_id: task_event_two_id).build_events }

    before do
      Timecop.freeze(Time.zone.now)
      # approved_modification_edit
      Timecop.travel(2.minutes.from_now)

      # Edit the request to create a request edit event
      approved_modification_edit.update!(request_reason: "I edited this request.",
                                         nonrating_issue_category: "CHAMPVA",
                                         nonrating_issue_description: "Newly edited issue description")

      Timecop.travel(2.minutes.from_now)
      approved_modification_edit.update!(status: "approved")
    end

    after do
      Timecop.return
    end

    context "Check for data output" do
      it "check for the correct data for Edited Request Modification" do
        visit "/decision_reviews/vha/tasks/#{task_event_two_id}/history"
        click_filter_option("Edit of request - issue modification (1)")

        original_modification_request = events.detect { |e| e.event_type == :request_edited }

        new_decision_date = original_modification_request.new_decision_date
        request_issue_decision_date = Date.parse(original_modification_request.decision_date)

        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)
        table_row = table.first('tr[id^="table-row"]')
        expect(table_row).to have_content("Edit of request - issue modification")
        expect(table_row).to have_content("New issue type: #{approved_modification_edit.nonrating_issue_category}")
        expect(table_row).to have_content(
          "New issue description: #{approved_modification_edit.nonrating_issue_description}"
        )
        expect(table_row).to have_content(
          "New decision date: #{approved_modification_edit.decision_date.strftime('%m/%d/%Y')}"
        )
        expect(table_row).to have_content(
          "New modification request reason: #{approved_modification_edit.request_reason}"
        )

        expect(table_row).to have_content("View original request")
        first("a", text: "View original request").click
        expect(table_row).to have_content("Hide original request")

        expect(table_row).to have_content("Benefit type: Veterans Health Administration")
        expect(table_row).to have_content("Current issue type: #{original_modification_request.issue_type}")
        expect(table_row).to have_content(
          "Current issue description: #{original_modification_request.issue_description}"
        )
        expect(table_row).to have_content(
          "Current decision date: #{request_issue_decision_date.strftime('%m/%d/%Y')}"
        )
        expect(table_row).to have_content("New issue type: #{original_modification_request.new_issue_type}")
        expect(table_row).to have_content(
          "New issue description: #{original_modification_request.new_issue_description}"
        )

        expect(table_row).to have_content("New decision date: #{new_decision_date.strftime('%m/%d/%Y')}")
        expect(table_row).to have_content(
          "Modification request reason: #{original_modification_request.previous_modification_request_reason}"
        )

        clear_filter_option("Edit of request - issue modification")

        step "check for the correct data for Approval of request - issue modification" do
          click_filter_option("Approval of request - issue modification (1)")

          original_modification_request = events.reverse.find { |e| e.event_type == :request_approved }
          new_decision_date = Date.parse(original_modification_request.new_decision_date)
          request_issue_decision_date = Date.parse(original_modification_request.decision_date)

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 1)
          table_row = table.first('tr[id^="table-row"]')
          expect(table_row).to have_content("Approval of request - issue modification")

          expect(table_row).to have_content("Request decision: #{
            original_modification_request.issue_modification_request_status == 'denied' ? 'Rejected' : 'Approved'
          }")

          expect(table_row).to have_content("Remove original issue: #{
            original_modification_request.remove_original_issue ? 'Yes' : 'No'
          }")
          expect(table_row).to have_content("Request originated by: #{original_modification_request.requestor}")

          expect(table_row).to have_content("View original request")
          first("a", text: "View original request").click
          expect(table_row).to have_content("Hide original request")

          expect(table_row).to have_content("Benefit type: Veterans Health Administration")
          expect(table_row).to have_content("Current issue type: #{original_modification_request.issue_type}")
          expect(table_row).to have_content(
            "Current issue description: #{original_modification_request.issue_description}"
          )
          expect(table_row).to have_content(
            "Current decision date: #{request_issue_decision_date.strftime('%m/%d/%Y')}"
          )
          expect(table_row).to have_content("New issue type: #{original_modification_request.new_issue_type}")
          expect(table_row).to have_content(
            "New issue description: #{original_modification_request.new_issue_description}"
          )
          expect(table_row).to have_content("New decision date: #{new_decision_date.strftime('%m/%d/%Y')}")
          expect(table_row).to have_content(
            "Modification request reason: #{original_modification_request.modification_request_reason}"
          )

          clear_filter_option("Approval of request - issue modification")
        end

        step "check for the correct data for denied request modification" do
          click_filter_option("Rejection of request - issue modification (1)")

          original_modification_request = events.detect { |e| e.event_type == :request_denied }
          new_decision_date = Date.parse(original_modification_request.new_decision_date)
          request_issue_decision_date = Date.parse(original_modification_request.decision_date)

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 1)
          table_row = table.first('tr[id^="table-row"]')
          expect(table_row).to have_content("Rejection of request - issue modification")

          expect(table_row).to have_content("Request decision: #{
            original_modification_request.issue_modification_request_status == 'denied' ? 'Rejected' : 'Approved'
          }")
          expect(table_row).to have_content("Request originated by: #{original_modification_request.requestor}")

          expect(table_row).to have_content("View original request")
          first("a", text: "View original request").click
          expect(table_row).to have_content("Hide original request")

          expect(table_row).to have_content("Benefit type: Veterans Health Administration")
          expect(table_row).to have_content("Current issue type: #{original_modification_request.issue_type}")
          expect(table_row).to have_content(
            "Current issue description: #{original_modification_request.issue_description}"
          )
          expect(table_row).to have_content(
            "Current decision date: #{request_issue_decision_date.strftime('%m/%d/%Y')}"
          )
          expect(table_row).to have_content("New issue type: #{original_modification_request.new_issue_type}")
          expect(table_row).to have_content(
            "New issue description: #{original_modification_request.new_issue_description}"
          )
          expect(table_row).to have_content("New decision date: #{new_decision_date.strftime('%m/%d/%Y')}")
          expect(table_row).to have_content(
            "Modification request reason: #{original_modification_request.modification_request_reason}"
          )

          clear_filter_option("Rejection of request - issue modification")
        end

        step "check for the correct data for Cancellation of request" do
          click_filter_option("Cancellation of request (1)")

          original_modification_request = events.detect { |e| e.event_type == :request_cancelled }

          new_decision_date = Date.parse(original_modification_request.new_decision_date)
          request_issue_decision_date = Date.parse(original_modification_request.decision_date)

          table = page.find("tbody")
          expect(table).to have_selector("tr", count: 1)
          table_row = table.first('tr[id^="table-row"]')
          expect(table_row).to have_content("Cancellation of request")

          expect(table_row).to have_content("Benefit type: Veterans Health Administration")
          expect(table_row).to have_content(
            "Current issue type: #{original_modification_request.issue_type}"
          )
          expect(table_row).to have_content(
            "Current issue description: #{original_modification_request.issue_description}"
          )
          expect(table_row).to have_content(
            "Current decision date: #{request_issue_decision_date.strftime('%m/%d/%Y')}"
          )
          expect(table_row).to have_content("New issue type: #{original_modification_request.new_issue_type}")
          expect(table_row).to have_content(
            "New issue description: #{original_modification_request.new_issue_description}"
          )
          expect(table_row).to have_content("New decision date: #{new_decision_date.strftime('%m/%d/%Y')}")
          expect(table_row).to have_content(
            "Modification request reason: #{original_modification_request.modification_request_reason}"
          )
        end
      end
    end
  end

  describe "check for cancelled claim" do
    let!(:cancelled_claim) do
      create(:supplemental_claim, :with_vha_issue, :with_update_users)
    end

    before do
      cancelled_claim.establish!
      cancelled_claim.request_issues.update(closed_status: "withdrawn", closed_at: Time.zone.now)
      cancelled_claim.tasks.update(status: "cancelled")
      cancelled_claim.reload

      visit "/decision_reviews/vha/tasks/#{cancelled_claim.tasks[0].id}/history"
    end

    context "should do expected details to show claim closed when cancelled" do
      it "Claim Cancelled" do
        click_filter_option("Claim closed (1)")

        table = page.find("tbody")
        expect(table).to have_selector("tr", count: 1)

        table_row = table.first("tr")
        expect(table_row).to have_content("Claim closed")
        expect(table_row).to have_content("Claim cancelled.")
      end
    end
  end
end
