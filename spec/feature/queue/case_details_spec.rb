require "rails_helper"

RSpec.feature "Case details" do
  let(:attorney_first_name) { "Robby" }
  let(:attorney_last_name) { "McDobby" }
  let!(:attorney_user) { FactoryBot.create(:user, full_name: "#{attorney_first_name} #{attorney_last_name}") }
  let!(:vacols_atty) do
    FactoryBot.create(
      :staff,
      :attorney_role,
      sdomainid: attorney_user.css_id,
      snamef: attorney_first_name,
      snamel: attorney_last_name
    )
  end

  let(:judge_first_name) { "Jane" }
  let(:judge_last_name) { "Ricotta-Lotta" }
  let!(:judge_user) { FactoryBot.create(:user, full_name: "#{judge_first_name} #{judge_last_name}") }
  let!(:vacols_judge) do
    FactoryBot.create(
      :staff,
      :judge_role,
      sdomainid: judge_user.css_id,
      snamef: judge_first_name,
      snamel: judge_last_name
    )
  end

  before do
    FeatureToggle.enable!(:test_facols)

    User.authenticate!(user: attorney_user)
  end

  after do
    FeatureToggle.disable!(:test_facols)
  end

  context "hearings pane on attorney task detail view" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: attorney_user,
          # Need a non-cancelled dispositon to show the full set of hearing attributes.
          case_hearings: case_hearings
        )
      )
    end
    let(:hearing) { appeal.hearings.first }

    context "when appeal has a single hearing that has already been held" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_held, user: judge_user)] }

      scenario "Entire set of attributes for hearing are displayed" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("Select an action")

        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Type: #{hearing_preference}")
        expect(page).to have_content("Date: #{hearing.date.strftime('%-m/%-e/%y')}")
        expect(page).to have_content("Judge: #{hearing.user.full_name}")
      end
    end

    context "when appeal has a single hearing that was cancelled" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_cancelled, user: judge_user)] }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        hearing = appeal.hearings.first
        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Type: #{hearing_preference}")

        expect(page).to have_content("Disposition: Cancelled")

        expect(page).to_not have_content("Date: ")
        expect(page).to_not have_content("Judge: ")
      end
    end

    context "when appeal has a single hearing with a HearingView" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_held, user: judge_user)] }
      before { HearingView.create(hearing_id: hearing.id, user_id: attorney_user.id).touch }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet/print']")
        expect(worksheet_link.text).to eq("View Hearing Worksheet")
      end
    end

    context "when appeal has no associated hearings" do
      let!(:case_hearings) { [] }

      scenario "Hearings info box is not displayed" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).not_to have_content("Hearing preference")
      end
    end
  end

  context "attorney case details view" do
    context "when Veteran is the appellant" do
      let!(:appeal) do
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: FactoryBot.create(:correspondent, sgender: "F", sdob: "1966-05-23")
          )
        )
      end

      scenario "details view informs us that the Veteran is the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Veteran")
        expect(page).to have_content("She/Her")
        expect(page).to have_content(appeal.veteran_date_of_birth.strftime("%-m/%e/%Y"))
      end
    end

    context "when Veteran is not the appellant" do
      let!(:appeal) do
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: FactoryBot.create(
              :correspondent,
              appellant_first_name: "Not",
              appellant_middle_initial: "D",
              appellant_last_name: "Veteran"
            )
          )
        )
      end

      scenario "details view informs us that the Veteran is not the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Appellant")
        expect(page).to have_content("About the Veteran")
        expect(page).to have_content(appeal.appellant_name)
        expect(page).to have_content(appeal.appellant_relationship)
        expect(page).to have_content(appeal.appellant_address_line_1)
      end
    end
  end

  context "when an appeal has some number of documents" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(:case_with_soc, :assigned, user: attorney_user)
      )
    end

    before { attorney_user.update!(roles: attorney_user.roles + ["Reader"]) }
    after { attorney_user.update!(roles: attorney_user.roles - ["Reader"]) }

    scenario "reader link appears on page and sends us to reader" do
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      # TODO: Why isn't the document count coming through here?
      # click_on "View #{appeal.documents.count} documents"
      click_on "View documents"

      # ["Caseflow", "> Reader"] are two elements, space handled by margin-left on second
      expect(page).to have_content("Caseflow> Reader")
      expect(page).to have_content("Back to #{appeal.veteran_full_name} (#{appeal.veteran_file_number})")

      click_on "Caseflow"
      expect(page.current_path).to eq "/queue"
    end
  end

  context "when an appeal has an issue with an allowed disposition" do
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: attorney_user,
          case_issues: [FactoryBot.create(:case_issue, :disposition_allowed)]
        )
      )
    end

    scenario "case details page shows appropriate text" do
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      expect(page.document.text).to match(/Disposition 1 - Allowed/i)
    end
  end

  context "loads judge task detail views" do
    let!(:vacols_case) do
      FactoryBot.create(
        :case,
        :assigned,
        user: judge_user,
        assigner: attorney_user,
        correspondent: FactoryBot.create(:correspondent, snamef: "Feffy", snamel: "Smeterino"),
        document_id: "1234567890"
      )
    end

    before do
      User.authenticate!(user: judge_user)
    end

    scenario "displays who prepared task" do
      tasks, appeals = LegacyWorkQueue.tasks_with_appeals(judge_user, "judge")
      task = tasks.first
      appeal = appeals.first

      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      preparer_name = "#{task.assigned_by.first_name[0]}. #{task.assigned_by.last_name}"
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_PREPARER_LABEL} #{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL} #{task.document_id}/i)
    end
  end
end
