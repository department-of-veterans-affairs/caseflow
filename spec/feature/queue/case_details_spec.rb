require "rails_helper"

RSpec.feature "Case details" do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:attorney_first_name) { "Robby" }
  let(:attorney_last_name) { "McDobby" }
  let!(:attorney_user) do
    FactoryBot.create(:user, full_name: "#{attorney_first_name} #{attorney_last_name}")
  end
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

        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_content("Select an action")

        expect(page).to have_content("Type: #{hearing.readable_request_type}")
        expect(page).to have_content("Date: #{hearing.scheduled_for.strftime('%-m/%-d/%y')}")
        expect(page).to have_content("Judge: #{hearing.user.full_name}")
      end

      scenario "Post remanded appeal shows indication of earlier appeal hearing" do
        visit "/queue"

        find_table_cell(post_remanded_appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_content("Select an action")
        expect(page).to have_content(COPY::CASE_DETAILS_HEARING_ON_OTHER_APPEAL)
      end
    end

    context "when appeal has a single hearing that was cancelled" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_cancelled, user: judge_user)] }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"

        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        hearing = appeal.hearings.first
        expect(page).to have_content("Type: #{hearing.readable_request_type}")

        expect(page).to have_content("Disposition: Cancelled")

        expect(page).to have_content("Date: ")
        expect(page).to have_content("Judge: ")
      end
    end

    context "when appeal has a single hearing with a HearingView" do
      let!(:case_hearings) { [FactoryBot.build(:case_hearing, :disposition_held, user: judge_user)] }
      before { HearingView.create(hearing: hearing, user_id: attorney_user.id).touch }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"
        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        worksheet_link = page.find("a[href='/hearings/#{hearing.external_id}/worksheet/print?keep_open=true']")
        expect(worksheet_link.text).to eq("View VLJ Hearing Worksheet")

        details_link = page.find("a[href='/hearings/#{hearing.external_id}/details']")
        expect(details_link.text).to eq("View Hearing Details")
      end
    end

    context "when appeal has no associated hearings" do
      let!(:case_hearings) { [] }

      scenario "Hearings info box is not displayed" do
        visit "/queue"
        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link
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

    context "when attorney has a case assigned in VACOLS without a DECASS record" do
      let!(:appeal) do
        FactoryBot.create(
          :legacy_appeal,
          vacols_case: FactoryBot.create(
            :case,
            :assigned,
            decass_count: 0,
            user: attorney_user
          )
        )
      end

      it "should not display a tasks action dropdown" do
        visit("/queue/appeals/#{appeal.external_id}")

        # Expect to find content we know to be on the page so that we wait for the page to load.
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page).not_to have_content("Select an action")
      end
    end
  end

  context "when an appeal has some number of documents" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(:case_with_soc, :assigned, :docs_in_vbms, user: attorney_user)
      )
    end

    before { attorney_user.update!(roles: attorney_user.roles + ["Reader"]) }
    after { attorney_user.update!(roles: attorney_user.roles - ["Reader"]) }

    scenario "reader link appears on page and sends us to reader" do
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      click_on "View #{appeal.documents.count} docs"

      # ["Caseflow", "> Reader"] are two elements, space handled by margin-left on second
      expect(page).to have_content("CaseflowQueue")
      expect(page).to have_content("Back to Your Queue #{appeal.veteran_full_name}")
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
        build_list(
          :request_issue,
          eligible_issue_cnt,
          contested_issue_description: "Knee pain"
        ),
        build_list(
          :request_issue,
          ineligible_issue_cnt,
          contested_issue_description: "Sunburn",
          ineligible_reason: :untimely
        )
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
      task = LegacyWorkQueue.tasks_for_user(judge_user).first
      appeal = task.appeal

      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

      preparer_name = "#{task.assigned_by.first_name[0]}. #{task.assigned_by.last_name}"

      # Wait for page to load some known content before testing for expected content.
      expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
      edit_link_url = "/queue/appeals/#{appeal.external_id}/modal/advanced_on_docket_motion"
      expect(page).to_not have_link("Edit", href: edit_link_url)
      expect(page.document.text).to match(/#{COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL} #{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL} #{task.document_id}/i)
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
      User.authenticate!(user: colocated_user)
    end

    scenario "displays task information" do
      visit "/queue"

      vet_name = on_hold_task.appeal.veteran_full_name
      assigner_name = on_hold_task.assigned_by_display_name

      click_on "On hold (1)"
      click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last}"

      expect(page).to have_content("TASK #{Constants::CO_LOCATED_ADMIN_ACTIONS[on_hold_task.action]}")
      find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
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
        OrganizationsUser.add_user_to_organization(user, AodTeam.singleton)
        User.authenticate!(user: user)
      end

      context "when requesting the case details page directly" do
        it "should display the edit link" do
          visit("/queue/appeals/#{appeal.external_id}")
          expect(page).to have_content("Edit")
        end
      end

      context "when reaching the case details page by way of the search page" do
        it "should display the edit link" do
          visit("/search")
          fill_in("searchBarEmptyList", with: appeal.veteran.file_number)
          click_on("Search")

          click_on(appeal.docket_number)
          expect(page).to have_content("Edit")
        end
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
        issue_description = "Head trauma 1"
        issue_description2 = "Head trauma 2"
        let!(:request_issue) do
          FactoryBot.create(
            :request_issue,
            review_request_id: appeal.id,
            contested_issue_description: issue_description,
            review_request_type: "Appeal"
          )
        end
        let!(:request_issue2) do
          FactoryBot.create(
            :request_issue,
            review_request_id: appeal.id,
            contested_issue_description: issue_description2,
            review_request_type: "Appeal"
          )
        end

        it "should display sorted issues" do
          visit "/queue/appeals/#{appeal.uuid}"
          expect(page).to have_content(issue_description + " Issue 2 DESCRIPTION " + issue_description2)
        end
      end
    end

    describe "Docket type badge shows up" do
      let!(:appeal) { FactoryBot.create(:appeal, docket_type: "direct_review") }

      it "should display docket type and number" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("D #{appeal.docket_number}")
      end
    end

    describe "CaseTimeline shows judge & attorney tasks" do
      let!(:user) { FactoryBot.create(:user) }
      let!(:appeal) { FactoryBot.create(:appeal) }
      let!(:appeal2) { FactoryBot.create(:appeal) }
      let!(:root_task) { create(:root_task, appeal: appeal, assigned_to: user) }
      let!(:attorney_task) do
        create(:ama_attorney_task, appeal: appeal, parent: root_task, assigned_to: user,
                                   closed_at: Time.zone.now - 4.days)
      end
      let!(:judge_task) do
        create(:ama_judge_decision_review_task, appeal: appeal, parent: attorney_task, assigned_to: user,
                                                status: Constants.TASK_STATUSES.completed,
                                                closed_at: Time.zone.now)
      end

      before do
        # This attribute needs to be set here due to update_parent_status hook in the task model
        attorney_task.update!(status: Constants.TASK_STATUSES.completed)
      end

      it "should display judge & attorney tasks" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(COPY::CASE_TIMELINE_ATTORNEY_TASK)
        expect(page).to have_content(COPY::CASE_TIMELINE_JUDGE_TASK)
      end

      it "should NOT display judge & attorney tasks" do
        visit "/queue/appeals/#{appeal2.uuid}"
        expect(page).not_to have_content(COPY::CASE_TIMELINE_JUDGE_TASK)
      end
    end
  end

  describe "AMA decision issue notes" do
    before { FeatureToggle.enable!(:ama_decision_issues) }
    after { FeatureToggle.disable!(:ama_decision_issues) }

    let(:request_issue) { create(:request_issue, description: "knee pain", notes: notes) }
    let(:appeal) { create(:appeal, number_of_claimants: 1, request_issues: [request_issue]) }

    context "when notes are nil" do
      let(:notes) { nil }

      it "does not display the Notes div" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to_not have_content("Note:")
      end
    end

    context "when notes are empty" do
      let(:notes) { "" }

      it "does not display the Notes div" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to_not have_content("Note:")
      end
    end
  end

  describe "Show multiple tasks" do
    let(:appeal) { create(:appeal) }
    let!(:root_task) do
      create(:root_task, appeal: appeal, assigned_to: judge_user,
                         status: Constants.TASK_STATUSES.assigned)
    end
    let(:instructions_text) { "note #1" }
    let!(:task) do
      create(:task, appeal: appeal, status: Constants.TASK_STATUSES.in_progress,
                    assigned_by: judge_user, assigned_to: attorney_user, type: GenericTask,
                    parent_id: root_task.id, started_at: rand(1..10).days.ago, instructions: [instructions_text])
    end

    context "single task" do
      it "one task is displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page).to have_content(task.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content("#{COPY::TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL.upcase} #{task.assigned_to.css_id}")
        expect(page).to have_content(COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase)
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTION_BOX_TITLE)
      end
      it "Show/hide task instructions" do
        visit "/queue/appeals/#{appeal.uuid}"

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(instructions_text)
        find("button", text: COPY::TASK_SNAPSHOT_HIDE_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to_not have_content(instructions_text)
      end
    end
    context "multiple tasks" do
      let!(:task2) do
        create(:task, appeal: appeal, status: Constants.TASK_STATUSES.in_progress,
                      assigned_by: judge_user, assigned_to: attorney_user, type: AttorneyTask,
                      parent_id: task.id, started_at: rand(1..20).days.ago)
      end
      let!(:task3) do
        create(:task, appeal: appeal, status: Constants.TASK_STATUSES.in_progress,
                      assigned_by: judge_user, assigned_to: attorney_user, type: AttorneyTask,
                      parent_id: task.id, started_at: rand(1..20).days.ago, assigned_at: 15.days.ago)
      end
      it "two tasks are displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(task2.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content(task2.assigned_to.css_id)
        expect(page).to have_content(task3.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content(task3.assigned_to.css_id)
        expect(page).to have_content("#{COPY::TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL.upcase} \
                                      #{task2.assigned_at.strftime('%m/%d/%Y')} \
                                      #{COPY::TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL.upcase}")
        expect(page).to have_content("#{COPY::TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL.upcase} \
                                      #{task3.assigned_to.css_id} \
                                      #{COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase}")
      end
    end
  end

  describe "Persist legacy tasks from backend" do
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    context "one task" do
      let!(:root_task) do
        create(:root_task, appeal: legacy_appeal, assigned_to: judge_user,
                           status: Constants.TASK_STATUSES.assigned)
      end
      let!(:legacy_task) do
        create(:task, appeal: legacy_appeal, status: Constants.TASK_STATUSES.in_progress,
                      assigned_by: judge_user, assigned_to: attorney_user, type: GenericTask,
                      parent_id: root_task.id, started_at: rand(1..10).days.ago)
      end

      it "is displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{legacy_appeal.vacols_id}"

        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page).to have_content(legacy_task.assigned_at.strftime("%m/%d/%Y"))
      end
    end
  end

  describe "VLJ and Attorney working case in Universal Case Title" do
    let(:attorney_user) { FactoryBot.create(:user) }
    let(:judge_user) { FactoryBot.create(:user) }
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:atty_task) do
      FactoryBot.create(:ama_attorney_task, appeal: appeal, parent: root_task, assigned_by: judge_user,
                                            assigned_to: attorney_user)
    end
    let!(:judge_task) do
      FactoryBot.create(:ama_judge_task, appeal: appeal, parent: atty_task, assigned_by: judge_user,
                                         assigned_to: judge_user)
    end

    context "Attorney has been assigned" do
      it "is displayed in the Universal Case Title" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ASSIGNED_JUDGE_LABEL)
        expect(page).to have_content(judge_user.full_name)
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ASSIGNED_ATTORNEY_LABEL)
        expect(page).to have_content(attorney_user.full_name)
      end
    end
  end

  describe "case timeline" do
    context "when the only completed task is a TrackVeteranTask" do
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:appeal) { root_task.appeal }
      let!(:tracking_task) do
        FactoryBot.create(
          :track_veteran_task,
          appeal: appeal,
          parent: root_task,
          status: Constants.TASK_STATUSES.completed
        )
      end

      it "should not show the tracking task in case timeline" do
        visit("/queue/appeals/#{tracking_task.appeal.uuid}")

        # Expect to only find the "NOD received" row and the "dispatch pending" rows.
        expect(page).to have_css("table#case-timeline-table tbody tr", count: 2)
      end
    end
  end

  describe "task snapshot" do
    context "when the only task is a TrackVeteranTask" do
      let(:root_task) { FactoryBot.create(:root_task) }
      let(:appeal) { root_task.appeal }
      let(:tracking_task) { FactoryBot.create(:track_veteran_task, appeal: appeal, parent: root_task) }

      it "should not show the tracking task in task snapshot" do
        visit("/queue/appeals/#{tracking_task.appeal.uuid}")
        expect(page).to have_content(COPY::TASK_SNAPSHOT_NO_ACTIVE_LABEL)
      end
    end

    context "when the only task is an IHP task" do
      let(:ihp_task) { FactoryBot.create(:informal_hearing_presentation_task) }

      it "should show the label for the IHP task" do
        visit("/queue/appeals/#{ihp_task.appeal.uuid}")
        expect(page).to have_content(COPY::IHP_TASK_LABEL)
      end
    end
  end
end
