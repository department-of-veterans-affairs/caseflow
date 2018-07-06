require "rails_helper"

def click_dropdown(opt_idx, container = page)
  dropdown = container.find(".Select-control")
  dropdown.click
  dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{opt_idx}']").click
end

RSpec.feature "Case details" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
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
      Generators::LegacyAppeal.build(
        vbms_id: "123456789S",
        vacols_record: vacols_record,
        documents: documents
      ),
      Generators::LegacyAppeal.build(
        vbms_id: "115555555S",
        vacols_record: vacols_record,
        documents: documents,
        issues: []
      )
    ]
  end
  let!(:issues) { [Generators::Issue.build] }
  let! :attorney_user do
    User.authenticate!(roles: ["System Admin"])
  end

  let!(:vacols_tasks) { Fakes::QueueRepository.tasks_for_user(attorney_user.css_id) }
  let!(:vacols_appeals) { Fakes::QueueRepository.appeals_from_tasks(vacols_tasks) }

  context "loads attorney task detail views" do
    before do
      User.unauthenticate!
      User.authenticate!(roles: ["System Admin"])
    end

    context "loads appeal summary view" do
      scenario "appeal has hearing" do
        appeal = vacols_appeals.reject { |a| a.hearings.empty? }.first
        hearing = appeal.hearings.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Select an action")

        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Type: #{hearing_preference}")

        if hearing.disposition.eql? :cancelled
          expect(page).to have_content("Disposition: Cancelled")
        else
          expect(page).to have_content("Date: #{hearing.date.strftime('%-m/%-e/%y')}")
          expect(page).to have_content("Judge: #{hearing.user.full_name}")

          unless hearing.hearing_views.empty?
            worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet/print']")
            expect(worksheet_link.text).to eq("View Hearing Worksheet")
          end
        end
      end

      scenario "appeal has no hearing" do
        task = vacols_tasks.select { |t| t.hearings.empty? }.first
        appeal = vacols_appeals.select { |a| a.vacols_id.eql? task.vacols_id }.first
        appeal_ro = appeal.regional_office

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).not_to have_content("Hearing preference")

        expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL} CAVC/i)
        expect(page).to have_content("Power of Attorney")
        expect(page).to have_content(appeal.representative)
        expect(page).to have_content("Regional Office: #{appeal_ro.city} (#{appeal_ro.key.sub('RO', '')})")
      end
    end

    context "loads appellant detail view" do
      scenario "veteran is the appellant" do
        appeal = vacols_appeals.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is the appellant.")

        expect(page).to have_content("She/Her")
        expect(page).to have_content(appeal.veteran_date_of_birth.strftime("%-m/%e/%Y"))
        expect(page).to have_content("The veteran is the appellant.")
      end

      scenario "veteran is not the appellant" do
        appeal = vacols_appeals.reject { |a| a.appellant_name.nil? }.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Appellant Details")
        expect(page).to have_content("Veteran Details")
        expect(page).to have_content(COPY::CASE_DIFF_VETERAN_AND_APPELLANT)

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

        sleep 1
        expect(page).to have_content(COPY::CASE_SNAPSHOT_ABOUT_BOX_TITLE)

        click_on "View #{appeal.documents.count} documents"

        # ["Caseflow", "> Reader"] are two elements, space handled by margin-left on second
        expect(page).to have_content("Caseflow> Reader")
        expect(page).to have_content("Back to #{appeal.veteran_full_name} (#{appeal.vbms_id})")

        click_on "Caseflow"
        expect(page.current_path).to eq "/queue"
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

  context "loads judge task detail views" do
    before do
      FeatureToggle.enable!(:test_facols)
      FeatureToggle.enable!(:judge_queue)
      FeatureToggle.enable!(:judge_assignment)
      User.unauthenticate!
      User.authenticate!(css_id: "BVAAABSHIRE")
      FeatureToggle.enable!(:judge_queue)
      RequestStore[:current_user] = judge
    end

    after do
      FeatureToggle.disable!(:test_facols)
      FeatureToggle.disable!(:judge_queue)
      FeatureToggle.disable!(:judge_assignment)
      User.unauthenticate!
      User.authenticate!
    end

    let!(:attorney) do
      User.create(
        css_id: "BVASCASPER1",
        station_id: User::BOARD_STATION_ID,
        full_name: "Archibald Franzduke"
      )
    end
    let!(:judge) { User.create(css_id: "BVAAABSHIRE", station_id: User::BOARD_STATION_ID) }
    let!(:judge_staff) { create(:staff, :judge_role, slogid: judge.css_id, sdomainid: judge.css_id) }
    let!(:vacols_case) do
      create(
        :case,
        :assigned,
        user: judge,
        assigner: attorney,
        correspondent: create(:correspondent, snamef: "Feffy", snamel: "Smeterino"),
        document_id: "1234567890"
      )
    end

    scenario "displays who prepared task" do
      tasks, appeals = LegacyWorkQueue.tasks_with_appeals(judge, "judge")

      task = tasks.first
      appeal = appeals.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id.sub('S', '')})"

      preparer_name = "#{task.assigned_by.first_name[0]}. #{task.assigned_by.last_name}"
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_PREPARER_LABEL} #{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL} #{task.document_id}/i)
    end
  end
end
