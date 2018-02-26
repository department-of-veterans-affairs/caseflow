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

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")

        added_by_name = FullName.new(
          appeal.added_by_first_name,
          appeal.added_by_middle_name,
          appeal.added_by_last_name
        ).formatted(:readable_full)
        assigned_date = appeal.date_assigned.strftime("%m/%d/%y")

        expect(page).to have_content("Assigned to you by #{added_by_name} on #{assigned_date}")
      end

      scenario "appeal has no assigner" do
        appeal = vacols_appeals.select { |a| a.added_by_first_name.nil? }.first
        visit "/queue"

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")
        assigned_date = appeal.date_assigned.strftime("%m/%d/%y")

        expect(page).to have_content("Assigned to you on #{assigned_date}")
      end
    end

    context "loads appeal summary view" do
      scenario "appeal has hearing" do
        appeal = vacols_appeals.reject { |a| a.hearings.empty? }.first
        hearing = appeal.hearings.first

        visit "/queue"

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")

        expect(page).to have_content("Hearing Preference: #{hearing.type.capitalize}")
        expect(page).to have_content("Hearing held: #{hearing.date.strftime('%-m/%-e/%y')}")
        expect(page).to have_content("Judge at hearing: #{hearing.user.full_name}")

        worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet']")
        expect(worksheet_link.text).to eq("View Hearing Worksheet")
      end

      scenario "appeal has no hearing" do
        appeal = vacols_tasks.select { |a| a.hearings.empty? }.first
        appeal_ro = appeal.regional_office

        visit "/queue"

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")

        expect(page).not_to have_content("Hearing Preference")

        expect(page).to have_content("Type: #{appeal.type}")
        expect(page).to have_content("Power of Attorney: #{appeal.representative}")
        expect(page).to have_content("Regional Office: #{appeal_ro.city} (#{appeal_ro.key.sub('RO', '')})")
      end
    end

    context "loads appellant detail view" do
      scenario "veteran is the appellant" do
        appeal = vacols_appeals.first

        visit "/queue"

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")
        find("#queue-tabwindow-tab-1").click

        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is the appellant.")

        expect(page).to have_content("She/Her")
        expect(page).to have_content(appeal.veteran_date_of_birth.strftime("%-m/%e/%Y"))
        expect(page).to have_content("The veteran is the appellant.")
      end

      scenario "veteran is not the appellant" do
        appeal = vacols_appeals.reject { |a| a.appellant_name.nil? }.first

        visit "/queue"

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")
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

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")

        expect(page).to have_content("Back to Your Queue")

        click_on "Open #{appeal.documents.length} documents in Caseflow Reader"

        expect(page).to have_content("Back to Draft Decision - #{appeal.veteran_full_name} (#{appeal.vbms_id})")
      end
    end
  end

  context "loads decision views" do
    context "submits decision" do
      scenario "submits omo decision" do
        appeal = vacols_appeals.first
        visit "/queue"

        safe_click("a[href='/queue/tasks/#{appeal.vacols_id}']")
        safe_click(".Select-control")
        safe_click("div[id$='--option-1']")

        expect(page).to have_link("Your Queue", href: "/queue/")
        expect(page).to have_link(appeal.veteran_full_name, href: "/queue/tasks/#{appeal.vacols_id}")
        expect(page).to have_link("Submit OMO", href: "/queue/tasks/#{appeal.vacols_id}/submit")

        expect(page).to have_content("Go back to draft decision #{appeal.vbms_id}")
      end
    end
  end
end
