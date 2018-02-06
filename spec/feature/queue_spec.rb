require "rails_helper"

RSpec.feature "Queue" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_welcome_gate)
  end

  after do
    FeatureToggle.disable!(:queue_welcome_gate)
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
    end
  end

  context "loads task detail views" do
    context "loads appellant detail view" do
      scenario "veteran is the appellant" do
        appeal = vacols_appeals.first

        visit "/queue"

        find(:xpath, "//a[text()='#{appeal.veteran_full_name}']").click
        find("#queue-tabwindow-tab-1").click

        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is the appellant.")

        vet_gender = appeal.veteran_gender
        vet_dob = appeal.veteran_date_of_birth

        expect(page).to have_content((vet_gender == "F") ? "She/Her" : "He/His")
        expect(page).to have_content(vet_dob.strftime("%-m/%e/%Y"))
        expect(page).to have_content("The veteran is the appellant.")
      end

      scenario "veteran is not the appellant" do
        appeal = vacols_appeals.reject { |a| a.appellant_name.nil? }.first

        visit "/queue"

        find(:xpath, "//a[text()='#{appeal.veteran_full_name}']").click
        find("#queue-tabwindow-tab-1").click

        expect(page).to have_content("Appellant Details")
        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is not the appellant.")

        expect(page).to have_content(appeal.appellant_name)
        expect(page).to have_content(appeal.appellant_relationship)
        expect(page).to have_content(appeal.appellant_address_line_1)
      end
    end
  end
end
