# frozen_string_literal: true

RSpec.feature "Case details", :all_dbs do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:attorney_first_name) { "Chanel" }
  let(:attorney_last_name) { "Afshari" }
  let!(:attorney_user) do
    create(:user, full_name: "#{attorney_first_name} #{attorney_last_name}")
  end
  let!(:vacols_atty) do
    create(
      :staff,
      :attorney_role,
      sdomainid: attorney_user.css_id,
      snamef: attorney_first_name,
      snamel: attorney_last_name
    )
  end

  let(:judge_first_name) { "Eeva" }
  let(:judge_last_name) { "Jovich" }
  let!(:judge_user) { create(:user, full_name: "#{judge_first_name} #{judge_last_name}") }
  let!(:vacols_judge) do
    create(
      :staff,
      :judge_role,
      sdomainid: judge_user.css_id,
      snamef: judge_first_name,
      snamel: judge_last_name
    )
  end

  let(:colocated_user) { create(:user) }
  let!(:vacols_colocated) { create(:staff, :colocated_role, sdomainid: colocated_user.css_id) }

  before do
    User.authenticate!(user: attorney_user)
  end

  context "hearings pane on attorney task detail view" do
    let(:veteran_first_name) { "Linda" }
    let(:veteran_last_name) { "Verne" }
    let!(:veteran) do
      create(
        :veteran,
        first_name: veteran_first_name,
        last_name: veteran_last_name,
        file_number: 123_456_789
      )
    end
    let!(:post_remanded_appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(
          :case,
          :assigned,
          :type_post_remand,
          bfcorlid: veteran.file_number,
          user: attorney_user
        )
      )
    end
    let!(:appeal) do
      create(
        :legacy_appeal,
        vacols_case: create(
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
      let!(:case_hearings) { [build(:case_hearing, :disposition_held, user: judge_user)] }

      scenario "Entire set of attributes for hearing are displayed" do
        visit "/queue"

        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_content("Select an action")
        expect(page).to have_content(COPY::CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY)
        expect(page).to have_content("Type: #{hearing.readable_request_type}")
        expect(page).to have_content("Date: #{hearing.scheduled_for.strftime('%-m/%-d/%y')}")
        expect(page).to have_content("Judge: #{hearing.user.full_name}")
      end

      scenario "post remanded appeal shows indication of earlier appeal hearing" do
        visit "/queue"

        find_table_cell(post_remanded_appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_content("Select an action")
        expect(page).to have_content(COPY::CASE_DETAILS_HEARING_ON_OTHER_APPEAL)
      end
    end

    context "when appeal has a single hearing that was cancelled" do
      let!(:case_hearings) { [build(:case_hearing, :disposition_cancelled, user: judge_user)] }

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
      let!(:case_hearings) { [build(:case_hearing, :disposition_held, user: judge_user)] }
      before { HearingView.create(hearing: hearing, user_id: attorney_user.id).touch }

      scenario "Fewer attributes of hearing are displayed" do
        visit "/queue"
        find_table_cell(appeal.vacols_id, COPY::CASE_LIST_TABLE_VETERAN_NAME_COLUMN_TITLE)
          .click_link

        expect(page).to have_current_path("/queue/appeals/#{appeal.vacols_id}")
        scroll_to("#hearings-section")
        worksheet_link = page.find(
          "a[href='/hearings/worksheet/print?keep_open=true&hearing_ids=#{hearing.external_id}']"
        )
        expect(worksheet_link.text).to eq(COPY::CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY)

        details_link = page.find("a[href='/hearings/#{hearing.external_id}/details']")
        expect(details_link.text).to eq(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)
      end

      context "the user has a VSO role", skip: "re-enable when pagination is fixed" do
        let!(:vso) { create(:vso, name: "VSO", role: "VSO", url: "vso-url", participant_id: "8054") }
        let!(:vso_user) { create(:user, :vso_role) }
        let!(:vso_task) { create(:ama_vso_task, :in_progress, assigned_to: vso, appeal: appeal) }

        before do
          vso.add_user(vso_user)
          allow_any_instance_of(Representative).to receive(:user_has_access?).and_return(true)
          User.authenticate!(user: vso_user)
        end

        scenario "worksheet and details links are not visible" do
          visit vso.path
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_current_path("/queue/appeals/#{appeal.vacols_id}")
          scroll_to("#hearings-section")
          expect(page).to_not have_content(COPY::CASE_DETAILS_HEARING_WORKSHEET_LINK_COPY)
          expect(page).to_not(
            have_css("a[href='/hearings/worksheet/print?keep_open=true&hearing_ids=#{hearing.external_id}']")
          )
          expect(page).to_not have_content(COPY::CASE_DETAILS_HEARING_DETAILS_LINK_COPY)
          expect(page).to_not have_css("a[href='/hearings/#{hearing.external_id}/details']")
        end
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
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: create(:correspondent, sgender: "F", sdob: "1966-05-23")
          )
        )
      end

      scenario "details view informs us that the Veteran is the appellant" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"

        expect(page).to have_content("About the Veteran")
        expect(page).not_to have_content("About the Appellant")
        expect(page).to have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE)
        expect(page).to have_content("1/10/1935")
        expect(page).to have_content(appeal.veteran_address_line_1)
        expect(page).to_not have_content("Regional Office")
      end

      scenario "when there is no POA" do
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_poa_by_file_number).and_return(nil)
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).to have_content("Power of Attorney")
        expect(page).to have_content(COPY::CASE_DETAILS_NO_POA)
      end
    end

    context "when veteran is not in BGS" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: create(:correspondent, sgender: "F")
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
        expect(page).not_to have_content("About the Appellant")
        expect(page).to have_content(COPY::CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE)
        expect(page).to_not have_content("1/10/1935")
        expect(page).to_not have_content("5/25/2016")
        expect(page).to_not have_content("Regional Office")
      end
    end
    context "when veteran is in BGS" do
      let!(:appeal) do
        create(
          :appeal
        )
      end
      scenario "details view informs us that the Veteran data source is BGS" do
        visit("/queue/appeals/#{appeal.external_id}")
        expect(page).to have_content("About the Veteran")
        expect(page).to have_content(COPY::CASE_DETAILS_VETERAN_ADDRESS_SOURCE)
        expect(page).to_not have_content("Regional Office")
      end
    end

    context "when Veteran is not the appellant" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: create(
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
        expect(page).to have_content(COPY::CASE_DETAILS_VETERAN_ADDRESS_SOURCE)
        expect(page).to_not have_content("Regional Office")
      end
    end

    context "when attorney has a case assigned in VACOLS without a DECASS record" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          vacols_case: create(
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

    context "veteran records have been merged and Veteran has multiple active phone numbers in SHARE" do
      let!(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            :assigned,
            user: attorney_user,
            correspondent: create(:correspondent, sgender: "F")
          )
        )
      end

      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = []
        Fakes::BGSService.inaccessible_appeal_vbms_ids << appeal.veteran_file_number
        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
          .and_raise(BGS::ShareError, "NonUniqueResultException")
      end

      scenario "access the appeal's case details", skip: "flake" do
        visit "/queue/appeals/#{appeal.external_id}"

        expect(page).to have_content(COPY::DUPLICATE_PHONE_NUMBER_TITLE)

        cache_key = Fakes::BGSService.new.can_access_cache_key(current_user, appeal.veteran_file_number)
        expect(Rails.cache.exist?(cache_key)).to eq(false)

        allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info).and_call_original
        Fakes::BGSService.inaccessible_appeal_vbms_ids = []
        visit "/queue/appeals/#{appeal.external_id}"

        expect(Rails.cache.exist?(cache_key)).to eq(true)
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

    context "with reader role" do
      before { attorney_user.update!(roles: attorney_user.roles + ["Reader"]) }
      after { attorney_user.update!(roles: attorney_user.roles - ["Reader"]) }

      scenario "reader link appears on page and sends us to reader" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        click_on "View #{appeal.documents.count} docs"

        expect(page).to have_content("CaseflowQueue")
        expect(page).to have_content("Back to your cases\n#{appeal.veteran_full_name}")
      end
    end

    context "with ro view hearing schedule role" do
      let(:roles) { ["RO ViewHearSched"] }
      let!(:attorney_user) { create(:user, roles: roles) }

      scenario "reader link does not appear on page" do
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).to have_content COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL
        expect(page).to_not have_content COPY::CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE.upcase
        expect(page).to_not have_content "View #{appeal.documents.count} docs"
      end

      context "also with build hearing schedule role" do
        let(:roles) { ["RO ViewHearSched", "Build HearSched"] }

        scenario "reader link appears on page" do
          visit "/queue"
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_content COPY::CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE.upcase
          expect(page).to have_content "View #{appeal.documents.count} docs"
        end
      end

      context "also with edit hearing schedule role" do
        let(:roles) { ["RO ViewHearSched", "Edit HearSched"] }

        scenario "reader link appears on page" do
          visit "/queue"
          click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
          expect(page).to have_content COPY::CASE_LIST_TABLE_APPEAL_DOCUMENT_COUNT_COLUMN_TITLE.upcase
          expect(page).to have_content "View #{appeal.documents.count} docs"
        end
      end
    end
  end

  context "when an appeal has an issue with an allowed disposition" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: attorney_user,
          case_issues: [create(:case_issue, :disposition_allowed)]
        )
      )
    end

    scenario "case details page shows appropriate text" do
      visit "/queue"
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      # Call have_content() so we wait for the case details page to load
      expect(page).to have_content(appeal.veteran_full_name)
      expect(page).to have_content("DISPOSITION\n1 - Allowed")
    end
  end

  context "when an appeal has an issue that is ineligible" do
    let(:issues) do
      [
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Knee pain"
        ),
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Sunburn",
          ineligible_reason: :untimely
        )
      ].flatten
    end
    let!(:appeal) { create(:appeal, request_issues: issues) }

    scenario "only eligible issues should appear in case details page" do
      visit "/queue/appeals/#{appeal.uuid}"

      expect(page).to have_content("Knee pain")
      expect(page).to_not have_content("Sunburn")
    end
  end

  context "when an appeal has an issue that is decided" do
    let(:issues) do
      [
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Knee pain"
        ),
        build_list(
          :request_issue,
          1,
          contested_issue_description: "Sunburn",
          closed_status: :decided,
          closed_at: 2.days.ago
        )
      ].flatten
    end
    let!(:appeal) { create(:appeal, request_issues: issues) }

    scenario "decided issues should appear in case details page" do
      visit "/queue/appeals/#{appeal.uuid}"

      expect(page).to have_content("Knee pain")
      expect(page).to have_content("Sunburn")
    end
  end

  context "loads judge task detail views" do
    let!(:vacols_case) do
      create(
        :case,
        :assigned,
        user: judge_user,
        assigner: attorney_user,
        correspondent: create(:correspondent, snamef: "Feffy", snamel: "Smeterino"),
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
      expect(page.document.text).to match(/#{COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase}\n#{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::TASK_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL}\n#{task.document_id}/i)
    end
  end

  context "when events are present" do
    let!(:appeal) { create(:legacy_appeal, vacols_case: vacols_case) }
    let!(:vacols_case) do
      create(
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

    context "when appeal is assigned to Pulac Cerullo" do
      let!(:appeal) do
        create(
          :appeal,
          veteran_file_number: "500000102",
          receipt_date: 6.months.ago.to_date.mdY,
          docket_type: Constants.AMA_DOCKETS.evidence_submission
        )
      end

      let!(:decision_document) do
        create(
          :decision_document,
          appeal: appeal,
          decision_date: 5.months.ago.to_date
        )
      end

      let!(:pulac_cerullo) do
        create(
          :pulac_cerullo_task,
          :completed,
          instructions: ["completed"],
          closed_at: 45.days.ago,
          appeal: appeal
        )
      end

      scenario "displays Pulac Cerullo task in order on  case timeline" do
        visit "/queue/appeals/#{appeal.external_id}"

        case_timeline_rows = page.find_all("table#case-timeline-table tbody tr")
        first_row_with_task = case_timeline_rows[0]
        second_row_with_task = case_timeline_rows[1]
        third_row_with_task = case_timeline_rows[2]
        expect(first_row_with_task).to have_content("PulacCerulloTask completed")
        expect(second_row_with_task).to have_content(COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA)
        expect(third_row_with_task).to have_content(COPY::CASE_TIMELINE_NOD_RECEIVED)
      end
    end

    context "when the appeal has hidden colocated tasks" do
      let(:appeal) { create(:appeal) }

      let!(:transcript_task) do
        create(:ama_colocated_task, :missing_hearing_transcripts, appeal: appeal).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      let!(:translation_task) do
        create(:ama_colocated_task, :translation, appeal: appeal).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      let!(:foia_task) do
        create(:ama_colocated_task, :foia, appeal: appeal).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end

      it "Does not display the intermediate colocated tasks" do
        visit "/queue/appeals/#{appeal.external_id}"

        case_timeline = page.find("table#case-timeline-table")
        expect(case_timeline).not_to have_content(transcript_task.class.name)
        expect(case_timeline).not_to have_content(translation_task.class.name)
        expect(case_timeline).not_to have_content(foia_task.class.name)
        expect(case_timeline).to have_content(transcript_task.children.first.class.name)
        expect(case_timeline).to have_content(translation_task.children.first.class.name)
        expect(case_timeline).to have_content(foia_task.children.first.class.name)
      end
    end
  end

  context "when there is a dispatch and decision_date" do
    let(:vacols_case) do
      create(:case, bfkey: "654321",
                    bfddec: 1.day.ago,
                    bfdnod: 2.days.ago,
                    bfd19: 1.day.ago)
    end
    let(:appeal) do
      create(:legacy_appeal, vacols_case: vacols_case)
    end

    before do
      User.authenticate!(user: judge_user)
    end

    scenario "ensure that the green checkmark appears next to the appropriate message when there is a decision date" do
      visit "/queue/appeals/#{appeal.external_id}"
      expect(find("tr", text: COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA)).to have_selector(".green-checkmark")
      expect(find("tr", text: COPY::CASE_TIMELINE_FORM_9_RECEIVED)).to have_selector(".green-checkmark")
    end
  end

  context "loads colocated task detail views" do
    let!(:appeal) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          :assigned,
          user: colocated_user,
          case_issues: create_list(:case_issue, 1)
        )
      )
    end

    before do
      User.authenticate!(user: colocated_user)
    end

    context "on hold task" do
      let!(:on_hold_task) do
        create(
          :colocated_task,
          :on_hold,
          assigned_to: colocated_user,
          assigned_by: attorney_user
        )
      end

      scenario "displays task information" do
        visit "/queue"

        vet_name = on_hold_task.appeal.veteran_full_name
        assigner_name = on_hold_task.assigned_by_display_name

        click_on "On hold (1)"
        click_on "#{vet_name.split(' ').first} #{vet_name.split(' ').last}"

        expect(page).to have_content("TASK\n#{on_hold_task.label}")
        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content("TASK INSTRUCTIONS\n#{on_hold_task.instructions[0].squeeze(' ').strip}")
        expect(page).to have_content("#{assigner_name.first[0]}. #{assigner_name.last}")

        expect(Task.find(on_hold_task.id).status).to eq("on_hold")
      end
    end

    context "assigned task" do
      let!(:assigned_task) do
        create(
          :colocated_task,
          assigned_to: colocated_user,
          assigned_by: attorney_user
        )
      end

      scenario "displays task bold in queue",
               skip: "https://circleci.com/gh/department-of-veterans-affairs/caseflow/65218, bat team investigated" do
        visit "/queue"
        vet_name = assigned_task.appeal.veteran_full_name
        fontweight_new = get_computed_styles("#veteran-name-for-task-#{assigned_task.id}", "font-weight")
        click_on vet_name
        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL, wait: 30)
        click_on "Caseflow"
        expect(page).to have_content(COPY::USER_QUEUE_PAGE_NEW_TASKS_DESCRIPTION, wait: 30)
        fontweight_visited = get_computed_styles("#veteran-name-for-task-#{assigned_task.id}", "font-weight")
        expect(fontweight_visited).to be < fontweight_new
      end
    end
  end

  context "edit aod link appears/disappears as expected" do
    let(:appeal) { create(:appeal) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }

    context "when the current user is a member of the AOD team" do
      before do
        AodTeam.singleton.add_user(user)
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
      let(:task) { create(:qr_task) }
      let(:user) { create(:user) }

      before do
        # Marking this task complete creates a BvaDispatchTask. Make sure there are members of that organization so
        # that the creation of that BvaDispatchTask succeeds.
        BvaDispatch.singleton.add_user(create(:user))
        qr.add_user(user)
        User.authenticate!(user: user)
      end

      it "marking task as complete works" do
        visit "/queue/appeals/#{task.appeal.uuid}"

        find(".Select-control", text: "Select an action").click
        find("div", class: "Select-option", text: Constants.TASK_ACTIONS.MARK_COMPLETE.label).click

        find("button", text: COPY::MARK_TASK_COMPLETE_BUTTON).click

        expect(page).to have_content(format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, "").squeeze(" "))
      end
    end

    describe "Issue order by created_at in Case Details page" do
      context "when there are two issues" do
        let!(:appeal) { create(:appeal) }
        issue_description = "Head trauma 1"
        issue_description2 = "Head trauma 2"
        benefit_text = "Benefit type: Compensation"
        diagnostic_text = "Diagnostic code: 5008"
        let!(:request_issue) do
          create(
            :request_issue,
            decision_review: appeal,
            contested_issue_description: issue_description
          )
        end
        let!(:request_issue2) do
          create(
            :request_issue,
            decision_review: appeal,
            contested_issue_description: issue_description2
          )
        end

        it "should display sorted issues with appropriate key value pairs" do
          visit "/queue/appeals/#{appeal.uuid}"
          issue_key = "Issue: "
          issue_value = issue_description
          issue_text = issue_key + issue_value
          expect(page).to have_content(issue_text)
          expect(page).to have_content(benefit_text)
          expect(page).to have_content(diagnostic_text)

          issue_value = issue_description2
          issue_text = issue_key + issue_value
          expect(page).to have_content(issue_text)
          expect(page).to have_content(benefit_text)
          expect(page).to have_content(diagnostic_text)
        end
      end
    end

    describe "Docket type badge shows up" do
      let!(:appeal) { create(:appeal, docket_type: Constants.AMA_DOCKETS.direct_review) }

      it "should display docket type and number" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content("D\n#{appeal.docket_number}")
      end
    end

    describe "CaseTimeline shows judge & attorney tasks" do
      let!(:user) { create(:user) }
      let!(:appeal) { create(:appeal) }
      let!(:appeal2) { create(:appeal) }
      let!(:root_task) { create(:root_task, appeal: appeal, assigned_to: user) }
      let!(:assign_task) { create(:ama_judge_task, appeal: appeal, assigned_to: user, parent: root_task) }
      let!(:judge_task) do
        create(
          :ama_judge_decision_review_task,
          appeal: appeal,
          parent: root_task,
          assigned_to: user
        )
      end
      let!(:attorney_task) { create(:ama_attorney_task, appeal: appeal, parent: judge_task, assigned_to: user) }
      let!(:attorney_task2) { create(:ama_attorney_task, appeal: appeal, parent: root_task, assigned_to: user) }

      before do
        # The status attribute needs to be set here due to update_parent_status hook in the task model
        # the updated_at attribute needs to be set here due to the set_timestamps hook in the task model
        assign_task.update!(status: Constants.TASK_STATUSES.completed, closed_at: "2019-01-01")
        attorney_task.update!(status: Constants.TASK_STATUSES.completed, closed_at: "2019-02-01")
        attorney_task2.update!(status: Constants.TASK_STATUSES.completed, closed_at: "2019-03-01")
        judge_task.update!(status: Constants.TASK_STATUSES.completed, closed_at: Time.zone.now)
      end

      it "should display judge & attorney tasks, but not judge assign tasks" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(COPY::CASE_TIMELINE_ATTORNEY_TASK)
        expect(page.find_all("dl", text: COPY::CASE_TIMELINE_JUDGE_TASK).length).to eq 1
      end

      it "should sort tasks properly" do
        visit "/queue/appeals/#{appeal.uuid}"
        case_timeline_rows = page.find_all("table#case-timeline-table tbody tr")
        first_row_with_date = case_timeline_rows[1]
        second_row_with_date = case_timeline_rows[2]
        third_row_with_date = case_timeline_rows[3]
        expect(first_row_with_date).to have_content("01/01/2020")
        expect(second_row_with_date).to have_content("03/01/2019")
        expect(third_row_with_date).to have_content("02/01/2019")
      end

      it "should NOT display judge & attorney tasks" do
        visit "/queue/appeals/#{appeal2.uuid}"
        expect(page).not_to have_content(COPY::CASE_TIMELINE_JUDGE_TASK)
      end
    end
  end

  describe "AMA decision issue notes" do
    let(:request_issue) { create(:request_issue, contested_issue_description: "knee pain", notes: notes) }
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
      create(:root_task, appeal: appeal, assigned_to: judge_user)
    end
    let(:instructions_text) { "note #1" }
    let!(:task) do
      create(:task,
             :in_progress,
             appeal: appeal,
             assigned_by: judge_user,
             assigned_to: attorney_user,
             type: Task,
             parent_id: root_task.id,
             started_at: rand(1..10).days.ago,
             instructions: [instructions_text])
    end

    context "single task" do
      it "one task is displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{appeal.uuid}"

        expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
        expect(page).to have_content(task.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content("#{COPY::TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL.upcase}\n#{task.assigned_to.css_id}")
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
        create(:task, :in_progress, appeal: appeal,
                                    assigned_by: judge_user, assigned_to: attorney_user, type: AttorneyTask,
                                    parent_id: task.id, started_at: rand(1..20).days.ago)
      end
      let!(:task3) do
        create(:task, :in_progress, appeal: appeal,
                                    assigned_by: judge_user, assigned_to: attorney_user, type: AttorneyTask,
                                    parent_id: task.id, started_at: rand(1..20).days.ago, assigned_at: 15.days.ago)
      end
      it "two tasks are displayed in the TaskSnapshot" do
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to have_content(task2.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content(task2.assigned_to.css_id)
        expect(page).to have_content(task3.assigned_at.strftime("%m/%d/%Y"))
        expect(page).to have_content(task3.assigned_to.css_id)

        assignment_date_label = COPY::TASK_SNAPSHOT_TASK_ASSIGNMENT_DATE_LABEL.upcase
        assigned_at_date = task2.assigned_at.strftime("%m/%d/%Y")
        days_since_label = COPY::TASK_SNAPSHOT_DAYS_SINCE_ASSIGNMENT_LABEL.upcase
        assigned_on_text = "#{assignment_date_label}\n#{assigned_at_date}\n#{days_since_label}"

        expect(page).to have_content(assigned_on_text)

        assignee_label = COPY::TASK_SNAPSHOT_TASK_ASSIGNEE_LABEL.upcase
        assigned_to = task3.assigned_to.css_id
        assignor_label = COPY::TASK_SNAPSHOT_TASK_ASSIGNOR_LABEL.upcase
        assigned_to_text = "#{assignee_label}\n#{assigned_to}\n#{assignor_label}"

        expect(page).to have_content(assigned_to_text)
      end
    end
  end

  describe "Persist legacy tasks from backend" do
    let(:legacy_appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    context "one task" do
      let!(:root_task) do
        create(:root_task, appeal: legacy_appeal, assigned_to: judge_user)
      end
      let!(:legacy_task) do
        create(:task, :in_progress, appeal: legacy_appeal,
                                    assigned_by: judge_user, assigned_to: attorney_user, type: Task,
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
    let(:attorney_user) { create(:user) }
    let(:judge_user) { create(:user) }
    let(:root_task) { create(:root_task) }
    let(:appeal) { root_task.appeal }
    let!(:request_issue) { create(:request_issue, decision_review: appeal) }
    let!(:judge_task) do
      create(
        :ama_judge_decision_review_task,
        appeal: appeal,
        parent: root_task,
        assigned_by: judge_user,
        assigned_to: judge_user
      )
    end
    let!(:atty_task) do
      create(
        :ama_attorney_task,
        appeal: appeal,
        parent: judge_task,
        assigned_by: judge_user,
        assigned_to: attorney_user
      )
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

    context "Attorney has removed appeal" do
      before { request_issue.remove! }
      it "should not show attorney name" do
        expect(appeal.reload.removed?).to eq(true)
        visit "/queue/appeals/#{appeal.uuid}"
        expect(page).to_not have_content(judge_user.full_name)
        expect(page).to_not have_content(attorney_user.full_name)
      end
    end
  end

  describe "case timeline" do
    context "when the only completed task is a TrackVeteranTask" do
      let(:root_task) { create(:root_task) }
      let(:appeal) { root_task.appeal }
      let!(:tracking_task) do
        create(
          :track_veteran_task,
          :completed,
          appeal: appeal,
          parent: root_task
        )
      end

      it "should not show the tracking task in case timeline" do
        visit("/queue/appeals/#{tracking_task.appeal.uuid}")
        # Expect to only find the "NOD received" row and the "dispatch pending" rows.
        expect(page).to have_css("table#case-timeline-table tbody tr", count: 2)
      end

      context "has withdrawn decision reviews" do
        let(:veteran) do
          create(:veteran,
                 first_name: "Bob",
                 last_name: "Winters",
                 file_number: "55555456")
        end

        let!(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 veteran_file_number: veteran.file_number,
                 docket_type: Constants.AMA_DOCKETS.direct_review,
                 receipt_date: 10.months.ago.to_date.mdY)
        end

        let!(:request_issue) do
          create(
            :request_issue,
            decision_review: appeal,
            contested_issue_description: "Left Knee",
            benefit_type: "compensation",
            decision_date: 8.months.ago.to_date.mdY,
            closed_status: "withdrawn",
            closed_at: 7.days.ago.to_datetime
          )
        end

        before do
          appeal.root_task.update!(status: Constants.TASK_STATUSES.cancelled)
        end

        scenario "withdraw entire review and show withdrawn on case timeline" do
          visit "/queue/appeals/#{appeal.uuid}"

          expect(page).to have_content(COPY::TASK_SNAPSHOT_TASK_WITHDRAWAL_DATE_LABEL.upcase)
          expect(page).to have_content("Appeal withdrawn")
        end
      end
    end

    context "when an AMA appeal has been dispatched from the Board" do
      let(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }

      before do
        judge = create(:user, station_id: 101)
        create(:staff, :judge_role, user: judge)
        judge_task = JudgeAssignTask.create!(appeal: appeal, parent: root_task, assigned_to: judge)

        atty = create(:user, station_id: 101)
        create(:staff, :attorney_role, user: atty)
        atty_task_params = [{ appeal: appeal, parent_id: judge_task.id, assigned_to: atty, assigned_by: judge }]
        atty_task = AttorneyTask.create_many_from_params(atty_task_params, judge).first

        atty_task.update!(status: Constants.TASK_STATUSES.completed)
        judge_task.update!(status: Constants.TASK_STATUSES.completed)

        bva_dispatcher = create(:user)
        BvaDispatch.singleton.add_user(bva_dispatcher)
        BvaDispatchTask.create_from_root_task(root_task)

        params = {
          appeal_id: appeal.external_id,
          citation_number: "12312312",
          decision_date: Date.new(1989, 11, 9).to_s,
          file: "longfilenamehere",
          redacted_document_location: "C://Windows/User/BVASWIFTT/Documents/NewDecision.docx"
        }
        BvaDispatchTask.outcode(appeal, params, bva_dispatcher)
      end

      it "displays the correct elements in case timeline" do
        visit("/queue/appeals/#{appeal.uuid}")

        expect(page).to_not have_content(root_task.timeline_title)
        expect(page).to_not have_content(COPY::CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING)
        expect(page).to_not have_css(".gray-dot")

        expect(page).to have_content(COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA)
      end
    end
  end

  describe "task snapshot" do
    context "when the only task is a TrackVeteranTask" do
      let(:root_task) { create(:root_task) }
      let(:appeal) { root_task.appeal }
      let(:tracking_task) { create(:track_veteran_task, appeal: appeal, parent: root_task) }

      it "should not show the tracking task in task snapshot" do
        visit("/queue/appeals/#{tracking_task.appeal.uuid}")
        expect(page).to have_content(COPY::TASK_SNAPSHOT_NO_ACTIVE_LABEL)
      end
    end

    context "when the only task is an IHP task" do
      let(:ihp_task) { create(:informal_hearing_presentation_task) }

      it "should show the label for the IHP task" do
        visit("/queue/appeals/#{ihp_task.appeal.uuid}")
        expect(page).to have_content(COPY::IHP_TASK_LABEL)
      end
    end
  end

  describe "AppealWithdrawalMailTask snapshot" do
    context "when child AppealWithdrawalMailTask is cancelled " do
      let!(:appeal) { create(:appeal) }
      let(:root_task) { create(:root_task, appeal: appeal) }

      let!(:appeal_withdrawal_mail_task) do
        create(
          :appeal_withdrawal_mail_task,
          appeal: appeal,
          instructions: ["cancelled"]
        )
      end

      let!(:appeal_withdrawal_bva_task) do
        create(
          :appeal_withdrawal_bva_task,
          appeal: appeal,
          parent: appeal_withdrawal_mail_task,
          instructions: ["cancelled"]
        )
      end

      let(:user) { create(:user) }

      before do
        BvaIntake.singleton.add_user(user)
        User.authenticate!(user: user)
      end

      it "displays AppealWithdrawalMailTask in case timeline" do
        visit("/queue/appeals/#{appeal.uuid}")

        prompt = COPY::TASK_ACTION_DROPDOWN_BOX_LABEL
        text = Constants.TASK_ACTIONS.CANCEL_TASK.label
        click_dropdown(prompt: prompt, text: text)
        click_button("Submit")

        expect(page).to have_content(format(COPY::CANCEL_TASK_CONFIRMATION, appeal.veteran_full_name))
        expect(page.current_path).to eq("/queue")

        click_on "Search"
        fill_in "searchBarEmptyList", with: appeal.veteran_file_number
        click_on "Search"
        click_on appeal.docket_number

        new_tasks = appeal_withdrawal_mail_task.reload.children
        expect(new_tasks.length).to eq(1)

        new_task = new_tasks.first
        expect(new_task.status).to eq Constants.TASK_STATUSES.cancelled
        expect(appeal_withdrawal_bva_task.assigned_to).to eq(BvaIntake.singleton)
        expect(appeal_withdrawal_bva_task.parent.assigned_to).to eq(MailTeam.singleton)
      end
    end
  end

  describe "Case details page access control" do
    let(:queue_home_path) { "/queue" }
    let(:case_details_page_path) { "/queue/appeals/#{appeal.external_id}" }

    context "when the current user does not have high enough BGS sensitivity level" do
      before do
        allow_any_instance_of(BGSService).to receive(:can_access?).and_return(false)
      end

      context "when the appeal is a legacy appeal" do
        let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }
        let!(:veteran) { create(:veteran, file_number: appeal.sanitized_vbms_id) }

        # Assign a task to the current user so that a row appears on the queue page.
        let!(:task) { create(:ama_attorney_task, appeal: appeal, assigned_to: attorney_user) }

        context "when we navigate directly to the case details page" do
          it "displays a loading failed message on the case details page" do
            visit(case_details_page_path)
            expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
            expect(page).to have_current_path(case_details_page_path)
          end
        end

        context "when we click into the case details page from the queue table view" do
          it "displays a loading failed message on the case details page" do
            visit(queue_home_path)
            click_on("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
            expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
            expect(page).to have_current_path(case_details_page_path)
          end
        end
      end
    end

    context "when the current user has high enough BGS sensitivity level" do
      before do
        allow_any_instance_of(BGSService).to receive(:can_access?).and_return(true)
      end

      context "when the appeal is a legacy appeal" do
        let!(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

        # Assign a task to the current user so that a row appears on the queue page.
        let!(:task) { create(:ama_attorney_task, appeal: appeal, assigned_to: attorney_user) }

        context "when we navigate directly to the case details page" do
          it "displays a loading failed message on the case details page" do
            visit(case_details_page_path)
            expect(page).to_not have_content(COPY::CASE_DETAILS_LOADING_FAILURE_TITLE)
            # The presence of the task snapshot element indicates that the case details page loaded.
            expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
            expect(page).to have_current_path(case_details_page_path)
          end
        end

        context "when we click into the case details page from the queue table view" do
          it "displays a loading failed message on the case details page" do
            visit(queue_home_path)
            click_on("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
            expect(page).to_not have_content(COPY::CASE_DETAILS_LOADING_FAILURE_TITLE)
            # The presence of the task snapshot element indicates that the case details page loaded.
            expect(page).to have_content(COPY::TASK_SNAPSHOT_ACTIVE_TASKS_LABEL)
            expect(page).to have_current_path(case_details_page_path)
          end
        end
      end
    end
  end
end
