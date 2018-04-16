require "rails_helper"

RSpec.feature "Queue" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_welcome_gate)
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
    FeatureToggle.disable!(:queue_welcome_gate)
    FeatureToggle.disable!(:queue_phase_two)
  end

  let(:documents) do
    [
      Generators::Document.create(
        filename: "My BVA Decision",
        type: "BVA Decision",
        received_at: 7.days.ago,
        vbms_document_id: 6,
        category_procedural: true,
        tags: [
          Generators::Tag.create(text: "New Tag1"),
          Generators::Tag.create(text: "New Tag2")
        ],
        description: Generators::Random.word_characters(50)
      ),
      Generators::Document.create(
        filename: "My Form 9",
        type: "Form 9",
        received_at: 5.days.ago,
        vbms_document_id: 4,
        category_medical: true,
        category_other: true
      ),
      Generators::Document.create(
        filename: "My NOD",
        type: "NOD",
        received_at: 1.day.ago,
        vbms_document_id: 3
      )
    ]
  end
  let(:vacols_record) { :remand_decided }
  let(:appeals) do
    [
      Generators::Appeal.build(vbms_id: "123456789S", vacols_record: vacols_record, documents: documents),
      Generators::Appeal.build(vbms_id: "115555555S", vacols_record: vacols_record, documents: documents, issues: [])
    ]
  end
  let!(:issues) { [Generators::Issue.build] }
  let!(:current_user) do
    User.authenticate!(roles: ["System Admin"])
  end

  let!(:vacols_tasks) { Fakes::QueueRepository.tasks_for_user(current_user.css_id) }
  let!(:vacols_appeals) { Fakes::QueueRepository.appeals_from_tasks(vacols_tasks) }

  context "search for appeals using veteran id" do
    scenario "appeal not found" do
      visit "/queue"
      fill_in "searchBar", with: "obviouslyfakecaseid"

      click_on "Search"

      expect(page).to have_content("Veteran ID not found")
    end

    scenario "vet found, has no appeal" do
      appeal = appeals.second

      visit "/queue"
      fill_in "searchBar", with: appeal.vbms_id

      click_on "Search"

      expect(page).to have_content("Veteran ID #{appeal.vbms_id} does not have any appeals.")
    end

    scenario "one appeal found" do
      appeal = appeals.first

      visit "/queue"
      fill_in "searchBar", with: (appeal.vbms_id + "\n")

      expect(page).to have_content("Select claims folder")
      expect(page).to have_content("Not seeing what you expected? Please send us feedback.")
      appeal_options = find_all(".cf-form-radio-option")
      expect(appeal_options.count).to eq(1)

      expect(appeal_options[0]).to have_content("Veteran #{appeal.veteran_full_name}")
      expect(appeal_options[0]).to have_content("Veteran ID #{appeal.vbms_id}")
      expect(appeal_options[0]).to have_content("Issues")
      expect(appeal_options[0].find_all("li").count).to eq(appeal.issues.size)

      appeal_options[0].click
      click_on "Okay"

      expect(page).to have_content("#{appeal.veteran_full_name}'s Claims Folder")
      expect(page).to have_link("Back to Your Queue", href: "/queue")
    end
  end

  context "loads queue table view" do
    scenario "table renders row per task" do
      visit "/queue"

      expect(page).to have_content("Your Queue")
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)
    end

    scenario "indicate if veteran is not appellant" do
      appeal = vacols_appeals.reject { |a| a.appellant_first_name.nil? }.first

      visit "/queue"

      appeal_row = find("tbody").find("#table-row-#{appeal.vacols_id}")
      first_cell = appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{appeal.veteran_full_name} (#{appeal.vbms_id})")
      expect(first_cell).to have_content("Veteran is not the appellant")
    end
  end

  context "loads task detail views" do
    context "displays who assigned task" do
      scenario "appeal has assigner" do
        appeal = vacols_appeals.select(&:added_by_first_name).first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        added_by_name = FullName.new(
          appeal.added_by_first_name,
          appeal.added_by_middle_name,
          appeal.added_by_last_name
        ).formatted(:readable_full)
        # TODO: these false positives are fixed in rubocop 0.53.0 (#5496)
        # rubocop:disable Style/FormatStringToken
        assigned_date = appeal.assigned_to_attorney_date.strftime("%m/%d/%y")
        # rubocop:enable Style/FormatStringToken

        expect(page).to have_content("Assigned to you by #{added_by_name} on #{assigned_date}")
      end

      scenario "appeal has no assigner" do
        appeal = vacols_appeals.select { |a| a.added_by_first_name.nil? }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        # rubocop:disable Style/FormatStringToken
        assigned_date = appeal.assigned_to_attorney_date.strftime("%m/%d/%y")
        # rubocop:enable Style/FormatStringToken

        expect(page).to have_content("Assigned to you on #{assigned_date}")
      end
    end

    context "loads appeal summary view" do
      scenario "appeal has hearing" do
        appeal = vacols_appeals.reject { |a| a.hearings.empty? }.first
        hearing = appeal.hearings.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Hearing preference: #{hearing_preference}")

        if hearing.disposition.eql? :cancelled
          expect(page).not_to have_content("Hearing date")
          expect(page).not_to have_content("Judge at hearing")
        else
          expect(page).to have_content("Hearing date: #{hearing.date.strftime('%-m/%-e/%y')}")
          expect(page).to have_content("Judge at hearing: #{hearing.user.full_name}")

          worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet/print']")
          expect(worksheet_link.text).to eq("View Hearing Worksheet")
        end
      end

      scenario "appeal has no hearing" do
        task = vacols_tasks.select { |t| t.hearings.empty? }.first
        appeal = vacols_appeals.select { |a| a.vacols_id.eql? task.vacols_id }.first
        appeal_ro = appeal.regional_office

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).not_to have_content("Hearing preference")

        expect(page).to have_content("Type: CAVC")
        expect(page).to have_content("Power of Attorney: #{appeal.representative}")
        expect(page).to have_content("Regional Office: #{appeal_ro.city} (#{appeal_ro.key.sub('RO', '')})")
      end
    end

    context "loads appellant detail view" do
      scenario "veteran is the appellant" do
        appeal = vacols_appeals.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        find("#queue-tabwindow-tab-1").click

        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is the appellant.")

        expect(page).to have_content("She/Her")
        # rubocop:disable Style/FormatStringToken
        expect(page).to have_content(appeal.veteran_date_of_birth.strftime("%-m/%e/%Y"))
        # rubocop:enable Style/FormatStringToken
        expect(page).to have_content("The veteran is the appellant.")
      end

      scenario "veteran is not the appellant" do
        appeal = vacols_appeals.reject { |a| a.appellant_name.nil? }.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        find("#queue-tabwindow-tab-1").click

        expect(page).to have_content("Appellant Details")
        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is not the appellant.")

        expect(page).to have_content(appeal.appellant_name)
        expect(page).to have_content(appeal.appellant_relationship)
        expect(page).to have_content(appeal.appellant_address_line_1)
      end
    end

    context "links to reader" do
      scenario "from appellant details page" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Your Queue > #{appeal.veteran_full_name}")

        click_on "Open #{number_with_delimiter(appeal.documents.length)} documents in Caseflow Reader"

        expect(page).to have_content("Back to #{appeal.veteran_full_name} (#{appeal.vbms_id})")
      end
    end

    context "displays issue dispositions" do
      scenario "from appellant details page" do
        appeal = vacols_appeals.first
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        expect(page).to have_content("Disposition: 1 - Allowed")
      end
    end
  end

  context "loads decision views" do
    context "prepares/fails to submit decision" do
      scenario "fails to submit omo decision" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        safe_click(".Select-control")
        safe_click("div[id$='--option-1']")

        expect(page).to have_link("Your Queue", href: "/queue/")
        expect(page).to have_link(appeal.veteran_full_name, href: "/queue/tasks/#{appeal.vacols_id}")
        expect(page).to have_link("Submit OMO", href: "/queue/tasks/#{appeal.vacols_id}/submit")

        expect(page).to have_content("Go back to #{appeal.veteran_full_name} (#{appeal.vbms_id})")

        click_on "Submit"

        expect(page).to have_content("This field is required")
        expect(page.find_all(".usa-input-error-message").length).to eq(3)
      end

      scenario "selects issue dispositions" do
        appeal = vacols_appeals.select { |a| a.issues.length > 1 }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        safe_click(".Select-control")
        safe_click("div[id$='--option-0']")

        expect(page).to have_content("Select Dispositions")

        table_rows = page.find_all("tr[id^='table-row-']")
        expect(table_rows.length).to eq(appeal.issues.length)

        # do not select all dispositions
        table_rows[0..0].each do |row|
          row.find(".Select-control").click
          row.find("div[id$='--option-1']").click
        end

        click_on "Finish dispositions"

        table_rows[1..-1].each do |row|
          dropdown_border = row.find(".issue-disposition-dropdown").native.css_value("border-left")
          expect(dropdown_border).to eq("4px solid rgb(205, 32, 38)")
        end

        # select all dispositions
        table_rows.each do |row|
          row.find(".Select-control").click
          row.find("div[id$='--option-2']").click
        end

        click_on "Finish dispositions"

        expect(page.current_path).to eq("/queue/tasks/#{appeal.vacols_id}/submit")
      end

      scenario "edits issue information" do
        appeal = vacols_appeals.reject { |a| a.issues.empty? }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        safe_click(".Select-control")
        safe_click("div[id$='--option-0']")

        expect(page).to have_content("Select Dispositions")

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}/dispositions/edit/1']")
        expect(page).to have_content("Edit Issue")

        enabled_fields = page.find_all(".Select--single:not(.is-disabled)")

        field_values = enabled_fields.map do |row|
          # changing options at the top of the form affects what options are enabled further down
          next if row.matches_css? ".is-disabled"

          row.find(".Select-control").click
          row.find("div[id$='--option-1']").click
          row.find(".Select-value-label").text
        end
        fill_in "Notes:", with: "this is the note"

        click_on "Save"

        expect(page).to have_content("You have updated issue 1.")
        expect(page).to have_content("Program: #{field_values.first}")
        expect(page).to have_content("Issue: #{field_values.second}")
        expect(page).to have_content("Note: this is the note")
      end

      scenario "deletes issue" do
        appeal = vacols_appeals.select { |a| a.issues.length > 1 }.first
        old_issues = appeal.issues
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        safe_click(".Select-control")
        safe_click("div[id$='--option-0']")

        expect(page).to have_content("Select Dispositions")

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(appeal.issues.length)

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}/dispositions/edit/1']")
        expect(page).to have_content("Edit Issue")

        issue_idx = appeal.issues.index { |i| i.vacols_sequence_id.eql? 1 }

        click_on "Delete Issue"
        expect(page).to have_content "Delete Issue?"
        click_on "Delete issue"

        expect(page).to have_content("You have deleted issue #{issue_idx + 1}")

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(old_issues.length - 1)
      end
    end

    context "submits decision" do
      scenario "submits omo decision" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        safe_click(".Select-control")
        safe_click("div[id$='--option-1']")

        expect(page).to have_content("Submit OMO for Review")

        click_label("omo-type_OMO - VHA")
        click_label("overtime")
        fill_in "document_id", with: "12345"
        fill_in "notes", with: "notes"

        safe_click("#select-judge")
        safe_click(".Select-control")
        safe_click("div[id$='--option-1']")
        expect(page).to have_content("Andrew Mackenzie")

        click_on "Submit"
        sleep 1
        expect(page).to(
          have_content(
            "Thank you for drafting #{appeal.veteran_full_name}'s outside medical
            opinion (OMO) request. It's been sent to Andrew Mackenzie for review."
          )
        )
        expect(page.current_path).to eq("/queue/")
      end

      scenario "submits draft decision" do
        appeal = vacols_appeals.select { |a| a.issues.length > 1 }.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        safe_click(".Select-control")
        safe_click("div[id$='--option-0']")

        issue_rows = page.find_all("tr[id^='table-row-']")
        expect(issue_rows.length).to eq(appeal.issues.length)

        issue_rows.each do |row|
          row.find(".Select-control").click
          row.find("div[id$='--option-#{issue_rows.index(row) % 7}']").click
        end

        click_on "Select remand reasons"
        expect(page).to have_content("Select Remand Reasons")

        remand_reasons = page.execute_script "return document.querySelectorAll('div[class^=\"checkbox-wrapper-\"]')"
        remand_reasons.sample(4).each(&:click)

        click_on "Review Draft Decision"
        expect(page).to have_content("Submit Draft Decision for Review")

        fill_in "document_id", with: "12345"
        fill_in "notes", with: "this is a decision note"

        safe_click "#select-judge"
        safe_click ".Select-control"
        safe_click "div[id$='--option-1']"
        expect(page).to have_content("Andrew Mackenzie")

        click_on "Submit"
        sleep 1
        expect(page).to(
          have_content(
            "Thank you for drafting #{appeal.veteran_full_name}'s decision.
            It's been sent to Andrew Mackenzie for review."
          )
        )
        expect(page.current_path).to eq("/queue/")
      end
    end
  end

  context "pop breadcrumb" do
    scenario "goes back from submit decision view" do
      appeal = vacols_appeals.reject { |a| a.issues.empty? }.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
      safe_click(".Select-control")
      safe_click("div[id$='--option-0']")

      issue_rows = page.find_all("tr[id^='table-row-']")
      expect(issue_rows.length).to eq(appeal.issues.length)

      issue_rows.each do |row|
        row.find(".Select-control").click
        row.find("div[id$='--option-2']").click
      end

      click_on "Finish dispositions"

      expect(page).to have_content("Submit Draft Decision for Review")
      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions > Submit")

      click_on "< Go back to #{appeal.veteran_full_name} (#{appeal.vbms_id})"

      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions")
      expect(page).not_to have_content("Select Dispositions > Submit")
    end
  end
end
