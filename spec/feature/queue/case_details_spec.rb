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

  let(:colocated_user) { FactoryBot.create(:user) }
  let!(:vacols_colocated) { FactoryBot.create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }

  before do
    User.authenticate!(user: attorney_user)
  end

  context "hearings pane on attorney task detail view" do
    let!(:veteran) do
      FactoryBot.create(
        :veteran,
        file_number: 123_456_789
      )
    end
    let!(:post_remanded_appeal) do
      FactoryBot.create(
        :legacy_appeal,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          :type_post_remand,
          bfcorlid: veteran.file_number,
          user: attorney_user
        )
      )
    end
    let!(:appeal) do
      FactoryBot.create(
        :legacy_appeal,
        vacols_case: FactoryBot.create(
          :case,
          :assigned,
          user: attorney_user,
          bfcorlid: veteran.file_number,
          # Need a non-cancelled disposition to show the full set of hearing attributes.
          case_hearings: case_hearings
        )
      )
    end
    let(:hearing) { appeal.hearings.first }

    context "when appeal has a single hearing that has already been held" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_held, user: judge_user)] }

      scenario "Entire set of attributes for hearing are displayed" do
        visit "/queue"
        page.find(:xpath, "//tr[@id='table-row-#{appeal.vacols_id}']/td[1]/a").click

        expect(page).to have_content("Select an action")

        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Type: #{hearing_preference}")
        expect(page).to have_content("Date: #{hearing.date.strftime('%-m/%-e/%y')}")
        expect(page).to have_content("Judge: #{hearing.user.full_name}")
      end

      scenario "Post remanded appeal shows indication of earlier appeal hearing" do
        visit "/queue"

        page.find(:xpath, "//tr[@id='table-row-#{post_remanded_appeal.vacols_id}']/td[1]/a").click

        expect(page).to have_content("Select an action")
        expect(page).to have_content(COPY::CASE_DETAILS_HEARING_ON_OTHER_APPEAL)
      end
    end

    context "when appeal has a single hearing that was cancelled" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_cancelled, user: judge_user)] }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"
        page.find(:xpath, "//tr[@id='table-row-#{appeal.vacols_id}']/td[1]/a").click

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
        page.find(:xpath, "//tr[@id='table-row-#{appeal.vacols_id}']/td[1]/a").click

        worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet/print?keep_open=true']")
        expect(worksheet_link.text).to eq("View Hearing Worksheet")
      end
    end

    context "when appeal has no associated hearings" do
      let!(:case_hearings) { [] }

      scenario "Hearings info box is not displayed" do
        visit "/queue"
        page.find(:xpath, "//tr[@id='table-row-#{appeal.vacols_id}']/td[1]/a").click
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
        expect(page).to have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE)
        expect(page).to have_content("1/10/1935")
        expect(page).to have_content("5/25/2016")
        expect(page).to have_content(appeal.regional_office.city)
        expect(page).to have_content(appeal.veteran_address_line_1)
      end
    end

    context "when veteran is not in BGS" do
      let!(:appeal) do
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: FactoryBot.create(:correspondent, sgender: "F")
          )
        )
      end

      before do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_return(nil)
      end

      scenario "details view informs us that the Veteran is the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Veteran")
        expect(page).to have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE)
        expect(page).to_not have_content("1/10/1935")
        expect(page).to_not have_content("5/25/2016")
        expect(page).to have_content(appeal.regional_office.city)
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
        expect(page).to have_content(appeal.veteran_address_line_1)
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
      click_on "View Veteran's documents"

      # ["Caseflow", "> Reader"] are two elements, space handled by margin-left on second
      expect(page).to have_content("Caseflow> Reader")
      expect(page).to have_content("Back to #{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
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

      # Call have_content() so we wait for the case details page to load
      expect(page).to have_content(appeal.veteran_full_name)
      expect(page.document.text).to match(/Disposition 1 - Allowed/i)
    end
  end

  context "when an appeal has an issue that is ineligible" do
    let(:eligible_issue_cnt) { 5 }
    let(:ineligible_issue_cnt) { 3 }
    let(:issues) do
      [
        build_list(:request_issue, eligible_issue_cnt, description: "Knee pain"),
        build_list(:request_issue, ineligible_issue_cnt, description: "Sunburn", ineligible_reason: :untimely)
      ].flatten
    end
    let!(:appeal) { FactoryBot.create(:appeal, request_issues: issues) }

    scenario "only eligible issues should appear in case details page" do
      visit "/queue/appeals/#{appeal.uuid}"

      expect(page).to have_content("Issue #{eligible_issue_cnt}")
      expect(page).to_not have_content("Issue #{eligible_issue_cnt + 1}")
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

  context "when events are present" do
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let!(:vacols_case) do
      FactoryBot.create(
        :case,
        bfdnod: 2.days.ago,
        bfd19: 1.day.ago
      )
    end

    before do
      User.authenticate!(user: judge_user)
    end

    scenario "displays case timeline" do
      visit "/queue/appeals/#{appeal.external_id}"

      # Ensure we see a timeline where completed things are checked and incomplete are gray
      expect(find("tr", text: COPY::CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING)).to have_selector(".gray-dot")
      expect(find("tr", text: COPY::CASE_TIMELINE_FORM_9_RECEIVED)).to have_selector(".green-checkmark")
    end
  end

  context "loads colocated task detail views" do
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
    let!(:on_hold_task) do
      FactoryBot.create(
        :colocated_task,
        :on_hold,
        assigned_to: colocated_user,
        assigned_by: attorney_user
      )
    end

    before do
      FeatureToggle.enable!(:colocated_queue)
      User.authenticate!(user: colocated_user)
    end

    after do
      FeatureToggle.disable!(:colocated_queue)
    end

    scenario "displays task information" do
      visit "/queue"

      vet_name = on_hold_task.appeal.veteran_full_name
      assigner_name = on_hold_task.assigned_by_display_name

      click_on "On hold (1)"
      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last}"

      expect(page).to have_content("TASK #{Constants::CO_LOCATED_ADMIN_ACTIONS[on_hold_task.action]}")
      expect(page).to have_content("TASK INSTRUCTIONS #{on_hold_task.instructions[0]}")
      expect(page).to have_content("#{assigner_name.first[0]}. #{assigner_name.last}")

      expect(Task.find(on_hold_task.id).status).to eq("on_hold")
    end
  end

  context "edit aod link appears/disappears as expected" do
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:user) { FactoryBot.create(:user) }
    let(:user2) { FactoryBot.create(:user) }

    context "when the current user is a member of the AOD team" do
      before do
        allow_any_instance_of(AodTeam).to receive(:user_has_access?).with(user).and_return(true)
        User.authenticate!(user: user)
        visit("/queue/appeals/#{appeal.uuid}")
      end

      it "should display the edit link" do
        expect(page).to have_content("Edit")
      end
    end

    context "when the current user is not a member of the AOD team" do
      before do
        allow_any_instance_of(AodTeam).to receive(:user_has_access?).with(user2).and_return(false)
        User.authenticate!(user: user2)
        visit("/queue/appeals/#{appeal.uuid}")
      end
      it "should not display the edit link" do
        expect(page).to_not have_content("Edit")
      end
    end
  end

  describe "Marking organization task complete" do
    context "when there is no assigner" do
      let(:qr) { QualityReview.singleton }
      let(:task) { FactoryBot.create(:qr_task) }
      let(:user) { FactoryBot.create(:user) }

      before do
        # Marking this task complete creates a BvaDispatchTask. Make sure there are members of that organization so
        # that the creation of that BvaDispatchTask succeeds.
        OrganizationsUser.add_user_to_organization(FactoryBot.create(:user), BvaDispatch.singleton)
        OrganizationsUser.add_user_to_organization(user, qr)
        User.authenticate!(user: user)
      end

      it "marking task as complete works" do
        visit "/queue/appeals/#{task.appeal.uuid}"

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click

        find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

        expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, ""))
      end
    end
    describe "Issue order by created_at in Case Details page" do
      context "when there are two issues" do
        let!(:appeal) { FactoryBot.create(:appeal) }
        issue_description = 'Head trauma 1'
        issue_description2 = 'Head trauma 2'
        let!(:request_issue) { FactoryBot.create(:request_issue, review_request_id: appeal.id, description: issue_description, review_request_type: "Appeal") }
        let!(:request_issue2) { FactoryBot.create(:request_issue, review_request_id: appeal.id, description: issue_description2, review_request_type: "Appeal") }

        it "should display sorted issues" do
          visit "/queue/appeals/#{appeal.uuid}"
          expect(page).to have_content(issue_description+ ' Issue 2 DESCRIPTION ' + issue_description2)
        end
      end
    end
  end
end
