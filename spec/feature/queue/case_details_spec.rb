require "rails_helper"

def click_dropdown(opt_idx, container = page)
  dropdown = container.find(".Select-control")
  dropdown.click
  dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{opt_idx}']").click
end

RSpec.feature "Case details" do
  let!(:attorney_user) { FactoryBot.create(:user) }
  let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  before do
    FeatureToggle.enable!(:queue_phase_two)
    FeatureToggle.enable!(:test_facols)

    User.authenticate!(user: attorney_user)
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:queue_phase_two)
  end

  context "loads attorney task detail views" do
    context "loads appeal summary view" do
      let!(:vacols_case_hearing) { FactoryBot.build(:case_hearing, user: attorney_user) }
      let!(:appeal_w_hearing) do
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            user: attorney_user,
            case_hearings: [vacols_case_hearing]
          )
        )
      end
      let(:hearing) { appeal_w_hearing.hearings.first }

      scenario "appeal has hearing" do
        visit "/queue"
        click_on "#{appeal_w_hearing.veteran_full_name} (#{appeal_w_hearing.sanitized_vbms_id})"

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
        expect(page).to have_content("Your Queue > #{appeal.veteran_full_name}")

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
        expect(page.document.text).to match(/Disposition 1 - Allowed/i)
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

  context "pop breadcrumb" do
    scenario "goes back from submit decision view" do
      appeal = vacols_appeals.select { |a| a.issues.map(&:disposition).uniq.eql? [nil] }.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
      sleep 1
      click_dropdown 0

      issue_rows = page.find_all("tr[id^='table-row-']")
      expect(issue_rows.length).to eq(appeal.issues.length)

      issue_rows.each { |row| click_dropdown 2, row }

      click_on "Continue"

      expect(page).to have_content("Submit Draft Decision for Review")
      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions > Submit")

      click_on "Back"

      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions")
      expect(page).not_to have_content("Select Dispositions > Submit")
    end
  end
end
