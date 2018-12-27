require "rails_helper"

RSpec.feature "Checkout flows" do
  let(:attorney_user) { FactoryBot.create(:default_user) }
  let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:judge_user) { FactoryBot.create(:user, station_id: User::BOARD_STATION_ID, full_name: "Aaron Judge") }
  let!(:vacols_judge) { FactoryBot.create(:staff, :judge_role, sdomainid: judge_user.css_id) }

  let(:colocated_user) { FactoryBot.create(:user) }
  let!(:vacols_colocated) { FactoryBot.create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }

  context "given a valid appeal and an attorney user" do
    let(:issue_note) { "Test note" }
    let(:issue_description) { "Tinnitus" }
    let!(:appeal) do
      FactoryBot.create(
        :appeal,
        number_of_claimants: 1,
        request_issues: FactoryBot.build_list(:request_issue, 1, description: issue_description, notes: issue_note)
      )
    end

    before do
      root_task = FactoryBot.create(:root_task)
      parent_task = FactoryBot.create(:ama_judge_task, assigned_to: judge_user, appeal: appeal, parent: root_task)

      FactoryBot.create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        parent: parent_task,
        appeal: appeal
      )

      User.authenticate!(user: attorney_user)
    end

    scenario "submits draft decision" do
      visit "/queue"
      click_on "(#{appeal.veteran_file_number})"

      expect(page).not_to have_content "Correct issues"

      click_dropdown(index: 0)
      click_label "radiation"

      click_on "Continue"

      # Ensure we can reload the flow and the special issue is saved
      click_on "Cancel"
      click_on "Yes, cancel"

      click_dropdown(index: 0)

      # Radiation should still be checked
      expect(page).to have_field("radiation", checked: true, visible: false)

      # Radiation should also be marked in the database
      expect(appeal.special_issue_list.radiation).to eq(true)
      click_on "Continue"

      expect(page).to have_content "Select disposition"
      issue_dispositions = page.find_all(
        ".Select-control",
        text: "Select disposition",
        count: appeal.request_issues.length
      )

      issue_dispositions.each do |row|
        row.click
        page.find("div", class: "Select-option", text: "Allowed").click
      end

      click_on "Continue"
      expect(page).to have_content("Submit Draft Decision for Review")

      document_id = Array.new(35).map { rand(10) }.join
      fill_in "document_id", with: document_id
      expect(page.find("#document_id").value.length).to eq 30

      fill_in "notes", with: "note"

      safe_click "#select-judge"
      click_dropdown(index: 0)

      click_on "Continue"
      expect(page).to have_content(COPY::NO_CASES_IN_QUEUE_MESSAGE)

      expect(page.current_path).to eq("/queue")
    end

    context "when ama issue feature toggle is turned on" do
      before do
        FeatureToggle.enable!(:ama_decision_issues, users: [attorney_user.css_id])
      end

      after do
        FeatureToggle.disable!(:ama_decision_issues, users: [attorney_user.css_id])
      end

      let(:decision_issue_text) { "This is a test decision issue" }
      let(:updated_decision_issue_text) { "This is updated text" }

      let(:other_issue_tex) { "This is a second issue" }
      let(:allowed_issue_tex) { "This is an allowed issue" }

      let(:decision_issue_disposition) { "Remanded" }
      let(:benefit_type) { "Education" }
      let(:old_benefit_type) { Constants::BENEFIT_TYPES[appeal.request_issues.first.benefit_type] }

      let!(:appeal) do
        FactoryBot.create(
          :appeal,
          number_of_claimants: 1,
          request_issues: FactoryBot.build_list(:request_issue, 2, description: issue_description, notes: issue_note)
        )
      end

      scenario "veteran is the appellant" do
        visit "/queue"
        click_on "(#{appeal.veteran_file_number})"

        # Ensure the issue is on the case details screen
        expect(page).to have_content(issue_description)
        expect(page).to have_content(issue_note)
        expect(page).to have_content "Correct issues"

        click_dropdown(index: 0)

        click_on "Continue"

        # Ensure the issue is on the select disposition screen
        expect(page).to have_content(issue_description)
        expect(page).to have_content(issue_note)

        expect(page).to have_content COPY::DECISION_ISSUE_PAGE_TITLE

        click_on "Continue"
        expect(page).to have_content "You must add a decision before you continue."

        # Add a first decision issue
        all("button", text: "+ Add decision", count: 2)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        click_on "Save"

        expect(page).to have_content "This field is required"
        fill_in "Text Box", with: decision_issue_text

        find(".Select-control", text: "Select disposition").click
        find("div", class: "Select-option", text: decision_issue_disposition).click

        find(".Select-control", text: old_benefit_type).click
        find("div", class: "Select-option", text: benefit_type).click

        click_on "Save"

        # Add a second decision issue
        all("button", text: "+ Add decision", count: 2)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: other_issue_tex

        find(".Select-control", text: "Select disposition").click
        find("div", class: "Select-option", text: decision_issue_disposition).click

        find(".Select-control", text: old_benefit_type).click
        find("div", class: "Select-option", text: benefit_type).click

        click_on "Save"

        # Add a third decision issue that's allowed
        all("button", text: "+ Add decision", count: 2)[0].click
        expect(page).to have_content COPY::DECISION_ISSUE_MODAL_TITLE

        fill_in "Text Box", with: allowed_issue_tex

        find(".Select-control", text: "Select disposition").click
        find("div", class: "Select-option", text: "Allowed").click

        find(".Select-control", text: old_benefit_type).click
        find("div", class: "Select-option", text: benefit_type).click

        find(".Select-control", text: "Select issues").click
        find("div", class: "Select-option", text: "Tinnitus").click

        click_on "Save"

        expect(page).to have_content("Added to 2 issues")

        # Test removing linked issue
        all("button", text: "Edit", count: 4)[2].click

        click_on "Remove"

        click_on "Save"

        expect(page).to_not have_content("Added to 2 issues")

        # Re-add linked issue
        all("button", text: "Edit", count: 3)[2].click

        find(".Select-control", text: "Select issues").click
        find("div", class: "Select-option", text: "Tinnitus").click

        click_on "Save"

        expect(page).to have_content("Added to 2 issues", count: 2)

        # Ensure the decision issue is on the select disposition screen
        expect(page).to have_content(decision_issue_text)
        expect(page).to have_content(decision_issue_disposition)

        expect(page).to have_content(other_issue_tex)

        click_on "Continue"

        find_field("Service treatment records", visible: false).sibling("label").click
        find_field("Post AOJ", visible: false).sibling("label").click

        click_on "Continue"
        # For some reason clicking too quickly on the next remand reason breaks the test.
        # Adding sleeps is bad... but I'm not sure how else to get this to work.
        sleep 1

        all("label", text: "Medical examinations", visible: false, count: 2)[1].click
        all("label", text: "Pre AOJ", visible: false, count: 2)[1].click

        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")

        document_id = Array.new(35).map { rand(10) }.join
        fill_in "document_id", with: document_id
        expect(page.find("#document_id").value.length).to eq 30

        fill_in "notes", with: "note"

        safe_click "#select-judge"
        click_dropdown(index: 0)

        click_on "Continue"
        expect(page).to have_content(COPY::NO_CASES_IN_QUEUE_MESSAGE)

        expect(page.current_path).to eq("/queue")

        expect(appeal.decision_issues.count).to eq(4)
        expect(appeal.decision_issues.first.description).to eq(decision_issue_text)
        expect(appeal.decision_issues.first.disposition).to eq("remanded")
        expect(appeal.decision_issues.first.benefit_type).to eq(benefit_type.downcase)

        remand_reasons = appeal.decision_issues.where(disposition: "remanded").map do |decision|
          decision.remand_reasons.first.code
        end

        expect(remand_reasons).to match_array(%w[service_treatment_records medical_examinations])
        expect(appeal.decision_issues.second.disposition).to eq("remanded")
        expect(appeal.decision_issues.third.disposition).to eq("allowed")
        expect(appeal.decision_issues.last.request_issues.count).to eq(2)

        # Switch to the judge and ensure they can update decision issues
        User.authenticate!(user: judge_user)
        visit "/queue"

        click_on "(#{appeal.veteran_file_number})"

        expect(page).to have_content "Correct issues"
        expect(page).to have_content("Added to 2 issues", count: 2)
        click_dropdown(index: 0)

        # Skip the special issues page
        click_on "Continue"

        expect(page).to have_content(decision_issue_text)

        # Update the decision issue
        all("button", text: "Edit", count: 4)[0].click
        fill_in "Text Box", with: updated_decision_issue_text
        click_on "Save"
        click_on "Continue"

        expect(page).to have_content("Review Remand Reasons")

        click_on "Continue"
        expect(page).to have_content("Issue 2 of 2")
        expect(find("input", id: "2-medical_examinations", visible: false).checked?).to eq(true)
        # Again, hate to add a sleep, but for some reason clicking continue too soon doesn't go
        # to the next page. I think it's related to how we're using continue to load the next
        # section of the remand reason screen.
        sleep 1

        click_on "Continue"

        expect(page).to have_content("Evaluate Decision")

        find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
        find("label", text: "5 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['outstanding']}").click
        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

        # The decision issue should have the new content the judge added
        expect(appeal.decision_issues.count).to eq(4)
        expect(appeal.decision_issues.first.description).to eq(updated_decision_issue_text)

        remand_reasons = appeal.decision_issues.where(disposition: "remanded").map do |decision|
          decision.remand_reasons.first.code
        end

        expect(remand_reasons).to match_array(%w[service_treatment_records medical_examinations])
        expect(appeal.decision_issues.where(disposition: "remanded").count).to eq(2)
        expect(appeal.decision_issues.where(disposition: "allowed").count).to eq(2)
        expect(appeal.request_issues.map { |issue| issue.decision_issues.count }).to match_array([3, 1])
      end
    end
  end

  context "given a valid legacy appeal and an attorney user" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: attorney_user,
          case_issues: case_issues
        )
      )
    end

    before { User.authenticate!(user: attorney_user) }

    context "with a single issue" do
      let(:case_issues) { FactoryBot.create_list(:case_issue, 1) }

      scenario "attorney checkout flow from case detail view loads" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        expect(page).to have_content "Select disposition"

        cancel_button = page.find "#button-cancel-button"
        expect(cancel_button.text).to eql "Cancel"
        cancel_button.click

        cancel_modal = page.find ".cf-modal"
        expect(cancel_modal.matches_css?(".active")).to eq true
        cancel_modal.find(".usa-button-warning").click

        click_dropdown(index: 1)

        expect(page).to have_content "Submit OMO for Review"

        cancel_button = page.find "#button-cancel-button"
        expect(cancel_button.text).to eql "Cancel"

        back_button = page.find "#button-back-button"
        expect(back_button.text).to eql "Back"
      end

      scenario "fails to submit omo decision when lacking required fields" do
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 1)

        expect(page).to have_content "Back"

        click_on "Continue"

        expect(page).to have_content("This field is required")
        expect(page.find_all(".usa-input-error-message").length).to eq(3)
      end
    end

    context "with three issues" do
      let(:case_issues) { FactoryBot.create_list(:case_issue, 3) }

      scenario "selects issue dispositions" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        expect(page).to have_content("Select disposition")

        table_rows = page.find_all("tr[id^='table-row-']")
        expect(table_rows.length).to eq(appeal.issues.length)

        # do not select all dispositions
        table_rows[0..0].each { |row| click_dropdown({ index: 1 }, row) }

        click_on "Continue"

        table_rows[1..-1].each do |row|
          dropdown_border = row.find(".issue-disposition-dropdown").native.css_value("border-left")
          expect(dropdown_border).to eq("4px solid rgb(205, 32, 38)")
        end

        # select all dispositions
        table_rows.each { |row| click_dropdown({ index: 2 }, row) }

        click_on "Continue"

        expect(page).to have_content("Submit Draft Decision for Review")
      end

      scenario "submits draft decision" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        issue_dispositions = page.find_all(".Select-control", text: "Select disposition", count: appeal.issues.length)

        # We want two issues to be a remand to make the remand reason screen show up.
        issue_dispositions.each_with_index do |row, index|
          disposition = (index == 0 || index == 1) ? "Remanded" : "Allowed"
          row.click
          page.find("div", class: "Select-option", text: disposition).click
        end

        click_on "Continue"
        expect(page).to have_content("Select Remand Reasons")
        expect(page).to have_content(appeal.issues.first.note)

        page.all("label", text: "Current findings", count: 1)[0].click
        page.all("label", text: "After certification", count: 1)[0].click
        click_on "Continue"

        expect(page).to have_content("Select Remand Reasons")
        expect(page).to have_content(appeal.issues.second.note)
        page.all("label", text: "Current findings", count: 2)[1].click
        page.all("label", text: "Before certification", count: 2)[1].click

        page.all("label", text: "Nexus opinion", count: 2)[1].click
        page.all("label", text: "After certification", count: 3)[2].click

        click_on "Continue"
        expect(page).to have_content("Submit Draft Decision for Review")

        document_id = Array.new(35).map { rand(10) }.join
        fill_in "document_id", with: document_id
        expect(page.find("#document_id").value.length).to eq 30

        fill_in "notes", with: "this is a decision note"

        # Expect this to be populated with all judge_staff we've created
        # by way of FactoryBot.create(:staff, :judge_role...
        safe_click "#select-judge"
        click_dropdown(index: 0)
        expect(page).to have_content(judge_user.full_name)

        click_on "Continue"
        expect(page).to have_content(COPY::NO_CASES_IN_QUEUE_MESSAGE)

        expect(page.current_path).to eq("/queue")
        expect(appeal.reload.issues.first.remand_reasons.size).to eq 1
        expect(appeal.issues.second.remand_reasons.size).to eq 2
        expect(appeal.issues.third.remand_reasons.size).to eq 0
      end

      scenario "submits omo request" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 1)

        expect(page).to have_content("Submit OMO for Review")

        click_label("omo-type_OMO - VHA")
        click_label("overtime")
        fill_in "document_id", with: "12345"

        click_on "Continue"
        expect(page).to have_content(COPY::FORM_ERROR_FIELD_INVALID)
        fill_in "document_id", with: "V1234567.1234"
        click_on "Continue"
        expect(page).not_to have_content(COPY::FORM_ERROR_FIELD_INVALID)

        dummy_note = generate_words 100
        fill_in "notes", with: dummy_note
        expect(page).to have_content(dummy_note[0..349])

        safe_click("#select-judge")
        click_dropdown(index: 0)
        expect(page).to have_content(judge_user.full_name)

        click_on "Continue"
        expect(page).to have_content(COPY::NO_CASES_IN_QUEUE_MESSAGE)

        case_review = AttorneyCaseReview.all.first
        expect(case_review.note.length).to eq 350
        expect(case_review.task_id.start_with?(appeal.vacols_id)).to be_truthy
      end

      scenario "deletes issue" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        expect(page).to have_content("Select disposition")

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(appeal.issues.length)

        first("a", text: "Edit Issue").click
        expect(page).to have_content("Edit Issue")

        # Before we delete the issue lets copy the count of issues before this action to new variable.
        old_issues_count = appeal.issues.length

        click_on "Delete Issue"
        expect(page).to have_content "Delete Issue?"
        click_on "Delete issue"

        expect(page).to have_content("You deleted issue 1.")

        visit "/queue"

        issue_count = find(:xpath, "//tbody/tr[@id='table-row-#{appeal.vacols_id}']/td[4]").text
        expect(issue_count.to_i).to eq(old_issues_count - 1)
      end
    end

    context "with a single issue with nil disposition" do
      # Default issue disposition is nil.
      let(:case_issues) { FactoryBot.create_list(:case_issue, 1) }

      def select_issue_level_options(opts)
        Array.new(5).map.with_index do |*, row_idx|
          # Issue level 2 and diagnostic code dropdowns render based on earlier
          # values, so we have to re-get elements per loop. There are at most 5
          # dropdowns rendered: Program, Type, Levels 1, 2, Diagnostic Code
          field_options = page.find_all ".Select--single"
          row = field_options[row_idx]

          next unless row

          row.find(".Select-control").click

          if opts[row_idx].eql? "*"
            # there're about 800 diagnostic code options, but getting the count
            # of '.Select-option's from the DOM takes a while
            row.find("div[id$='--option-#{rand(800)}']").click
          elsif opts[row_idx].is_a? String
            row.find("div[id$='--option-#{opts[row_idx]}']").click
          end
          row.find(".Select-value-label").text
        end
      end

      scenario "edits issue information" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        expect(page).to have_content("Select disposition")

        first("a", text: "Edit Issue").click
        expect(page).to have_content("Edit Issue")

        enabled_fields = page.find_all(".Select--single:not(.is-disabled)")

        field_values = enabled_fields.map do |row|
          # changing options at the top of the form affects what options are enabled further down
          next if row.matches_css? ".is-disabled"

          click_dropdown({ index: 1 }, row)
          row.find(".Select-value-label").text
        end
        fill_in "Notes:", with: "this is the note"

        click_on "Continue"

        expect(page).to have_content "You updated issue 1."
        expect(page).to have_content "Program: #{field_values.first}"
        expect(page).to have_content "Issue: #{field_values.second}"
        expect(page).to have_content field_values.last # diagnostic code
        expect(page).to have_content "Note: this is the note"
      end

      scenario "shows/hides diagnostic code option" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        expect(page).to have_content "Select disposition"

        diag_code_no_l2 = %w[4 5 0 *]
        no_diag_code_no_l2 = %w[4 5 1]
        diag_code_w_l2 = %w[4 8 0 1 *]
        no_diag_code_w_l2 = %w[4 8 0 2]

        [diag_code_no_l2, no_diag_code_no_l2, diag_code_w_l2, no_diag_code_w_l2].each do |opt_set|
          expect(page).to have_content "Edit Issue"
          click_link("Edit Issue", match: :first)
          expect(page).to have_content "Program"
          selected_vals = select_issue_level_options(opt_set)
          click_on "Continue"
          selected_vals.each { |v| expect(page).to have_content v }
        end
      end

      scenario "adds issue" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"
        click_dropdown(index: 0)

        expect(page).to have_content "Select disposition"

        click_on "Add Issue"
        expect(page).to have_content "Add Issue"

        delete_btn = find("button", text: "Delete Issue")
        expect(delete_btn.disabled?).to eq true

        program = "BVA Original Jurisdiction"
        issue = "Motions"
        level = "Rule 608 motion to withdraw"

        find(".Select-control", text: "Select program").click
        find("div", class: "Select-option", text: program).click

        find(".Select-control", text: "Select issue").click
        find("div", class: "Select-option", text: issue).click

        find(".Select-control", text: "Select level 1").click
        find("div", class: "Select-option", text: level).click

        fill_in "Notes:", with: "added issue"

        click_on "Continue"

        expect(page).to have_content "You created a new issue."
        expect(page).to have_content "Program: #{program}"
        expect(page).to have_content "Issue: #{issue}"
        expect(page).to have_content level
        expect(page).to have_content "Note: added issue"

        visit "/queue"

        expect(appeal.reload.issues.length).to eq 2
      end
    end
  end

  context "given a valid ama appeal with single issue assigned to current judge user" do
    let!(:appeal) do
      FactoryBot.create(
        :appeal,
        number_of_claimants: 1,
        request_issues: FactoryBot.build_list(:request_issue, 1, description: "Tinnitus", disposition: "allowed")
      )
    end

    let(:root_task) { FactoryBot.create(:root_task) }
    let(:parent_task) do
      FactoryBot.create(
        :ama_judge_review_task,
        :in_progress,
        assigned_to: judge_user,
        appeal: appeal,
        parent: root_task
      )
    end

    let(:child_task) do
      FactoryBot.create(
        :ama_attorney_task,
        :in_progress,
        assigned_to: attorney_user,
        assigned_by: judge_user,
        parent: parent_task,
        appeal: appeal
      )
    end

    before do
      child_task.mark_as_complete!
      User.authenticate!(user: attorney_user)
    end

    before do
      FeatureToggle.enable!(:judge_case_review_checkout)

      User.authenticate!(user: judge_user)
    end

    after do
      FeatureToggle.disable!(:judge_case_review_checkout)
    end

    scenario "starts dispatch checkout flow" do
      visit "/queue"
      click_on "(#{appeal.veteran_file_number})"

      click_dropdown(index: 0) do
        visible_options = page.find_all(".Select-option")
        expect(visible_options.length).to eq 1
        expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_DISPATCH_LABEL
      end

      # Special Issues screen
      click_on "Continue"
      # Request Issues screen
      click_on "Continue"
      expect(page).to have_content("Evaluate Decision")

      expect(page).to_not have_content("One Touch Initiative")

      find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
      text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
      find("label", text: text_to_click).click
      find("#issues_are_not_addressed", visible: false).sibling("label").click

      dummy_note = generate_words 5
      fill_in "additional-factors", with: dummy_note
      expect(page).to have_content(dummy_note[0..5])

      click_on "Continue"
      expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
      case_review = JudgeCaseReview.find_by(task_id: parent_task.id)
      expect(case_review.attorney).to eq attorney_user
      expect(case_review.judge).to eq judge_user
      expect(case_review.complexity).to eq "easy"
      expect(case_review.quality).to eq "does_not_meet_expectations"
      expect(case_review.one_touch_initiative).to eq false
    end
  end

  context "given a valid legacy appeal with single issue assigned to current judge user" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: judge_user,
          assigner: attorney_user,
          case_issues: [
            FactoryBot.create(:case_issue, :disposition_allowed),
            FactoryBot.create(:case_issue, :disposition_granted_by_aoj)
          ],
          work_product: work_product
        )
      )
    end

    before do
      FeatureToggle.enable!(:judge_case_review_checkout)

      User.authenticate!(user: judge_user)
    end

    after do
      FeatureToggle.disable!(:judge_case_review_checkout)
    end

    context "where work product is decision draft" do
      let(:work_product) { :draft_decision }

      scenario "starts dispatch checkout flow" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.sanitized_vbms_id})"

        click_dropdown(index: 0) do
          visible_options = page.find_all(".Select-option")
          expect(visible_options.length).to eq 1
          expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_DISPATCH_LABEL
        end

        # one issue is decided, excluded from checkout flow
        expect(appeal.issues.length).to eq 2
        expect(page.find_all(".issue-disposition-dropdown").length).to eq 1

        click_on "Continue"
        expect(page).to have_content("Evaluate Decision")

        expect(page).to have_content("One Touch Initiative")
        find("label", text: COPY::JUDGE_EVALUATE_DECISION_CASE_ONE_TOUCH_INITIATIVE_SUBHEAD).click

        find("label", text: Constants::JUDGE_CASE_REVIEW_OPTIONS["COMPLEXITY"]["easy"]).click
        text_to_click = "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
        find("label", text: text_to_click).click

        find("#issues_are_not_addressed", visible: false).sibling("label").click

        dummy_note = generate_words 5
        fill_in "additional-factors", with: dummy_note
        expect(page).to have_content(dummy_note[0..5])

        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_DISPATCH_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)

        expect(VACOLS::Decass.find(appeal.vacols_id).de1touch).to eq "Y"
      end
    end

    context "where work product is omo request" do
      let(:work_product) { :omo_request }

      scenario "completes assign to omo checkout flow" do
        visit "/queue/appeals/#{appeal.vacols_id}"

        click_dropdown(index: 0) do
          visible_options = page.find_all(".Select-option")
          expect(visible_options.length).to eq 1
          expect(visible_options.first.text).to eq COPY::JUDGE_CHECKOUT_OMO_LABEL
        end

        expect(page).to have_content("Evaluate Decision")

        radio_group_cls = "usa-fieldset-inputs cf-form-radio "
        case_complexity_opts = page.find_all(:xpath, "//fieldset[@class='#{radio_group_cls}'][1]//label")
        case_quality_opts = page.find_all(:xpath, "//fieldset[@class='#{radio_group_cls}'][2]//label")

        expect(case_quality_opts.first.text).to eq(
          "5 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['outstanding']}"
        )
        expect(case_quality_opts.last.text).to eq(
          "1 - #{Constants::JUDGE_CASE_REVIEW_OPTIONS['QUALITY']['does_not_meet_expectations']}"
        )

        case_complexity_opts[0].click
        case_quality_opts[2].click
        # areas of improvement
        areas_of_improvement = page.find_all(
          :xpath, "//fieldset[@class='checkbox-wrapper-Identify areas for improvement cf-form-checkboxes']//label"
        )
        areas_of_improvement[0].double_click
        areas_of_improvement[5].double_click

        dummy_note = "lorem ipsum dolor sit amet"
        fill_in "additional-factors", with: dummy_note

        click_on "Continue"

        expect(page).to have_content(COPY::JUDGE_CHECKOUT_OMO_SUCCESS_MESSAGE_TITLE % appeal.veteran_full_name)
        decass = VACOLS::Decass.find_by(defolder: appeal.vacols_id, deadtim: Time.zone.today)
        expect(decass.decomp).to eq(VacolsHelper.local_date_with_utc_timezone)
        expect(decass.deoq).to eq("3")
      end
    end
  end

  context "given a valid legacy appeal and a colocated user" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: colocated_user,
          case_issues: FactoryBot.create_list(:case_issue, 1)
        )
      )
    end
    let!(:appeal_with_translation_task) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: colocated_user,
          case_issues: FactoryBot.create_list(:case_issue, 1)
        )
      )
    end
    let!(:colocated_action) do
      FactoryBot.create(
        :colocated_task,
        appeal: appeal,
        assigned_to: colocated_user,
        assigned_by: attorney_user,
        action: "pending_scanning_vbms"
      )
    end
    let!(:translation_action) do
      FactoryBot.create(
        :colocated_task,
        appeal: appeal_with_translation_task,
        assigned_to: colocated_user,
        assigned_by: attorney_user,
        action: "translation"
      )
    end

    before do
      FeatureToggle.enable!(:colocated_queue)
      User.authenticate!(user: colocated_user)
    end

    after do
      FeatureToggle.disable!(:colocated_queue)
    end

    scenario "reassigns task to assigning attorney" do
      visit "/queue"

      appeal = colocated_action.appeal

      vet_name = appeal.veteran_full_name

      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last} (#{appeal.sanitized_vbms_id})"
      click_dropdown(index: 0)

      expect(page).to have_content(COPY::MARK_TASK_COMPLETE_BUTTON)
      click_on COPY::MARK_TASK_COMPLETE_BUTTON

      expect(page).to have_content(
        format(COPY::MARK_TASK_COMPLETE_CONFIRMATION, vet_name)
      )

      expect(colocated_action.reload.status).to eq "completed"
      expect(colocated_action.assigned_at.to_date).to eq Time.zone.today
    end

    scenario "places task on hold" do
      visit "/queue"

      appeal = colocated_action.appeal

      vet_name = appeal.veteran_full_name
      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last} (#{appeal.sanitized_vbms_id})"

      expect(page).to have_content("Actions")

      click_dropdown(index: 1)

      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_PLACE_HOLD_HEAD, vet_name, appeal.sanitized_vbms_id)
      )

      click_dropdown(index: 6)
      expect(page).to have_content(COPY::COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY)

      hold_duration = [rand(100), 1].max
      fill_in COPY::COLOCATED_ACTION_PLACE_CUSTOM_HOLD_COPY, with: hold_duration

      instructions = generate_words 5
      fill_in "instructions", with: instructions
      click_on "Place case on hold"

      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_PLACE_HOLD_CONFIRMATION, vet_name, hold_duration)
      )
      expect(colocated_action.reload.on_hold_duration).to eq hold_duration
      expect(colocated_action.status).to eq "on_hold"
      expect(colocated_action.instructions[1]).to eq instructions
    end

    scenario "sends task to team" do
      visit "/queue"

      appeal = translation_action.appeal
      vacols_case = appeal.case_record

      team_name = Constants::CO_LOCATED_ADMIN_ACTIONS[translation_action.action]
      vet_name = appeal.veteran_full_name
      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last} (#{appeal.sanitized_vbms_id})"

      click_dropdown(index: 0)

      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_HEAD, team_name)
      )
      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_COPY, vet_name, appeal.sanitized_vbms_id)
      )

      click_on COPY::COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON

      expect(page).to have_content(
        format(COPY::COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_CONFIRMATION, vet_name, team_name)
      )

      expect(translation_action.reload.status).to eq "completed"
      expect(vacols_case.reload.bfcurloc).to eq LegacyAppeal::LOCATION_CODES[translation_action.action.to_sym]
    end
  end
end
