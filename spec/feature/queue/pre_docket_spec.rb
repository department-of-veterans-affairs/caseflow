# frozen_string_literal: true

RSpec.feature "Pre-Docket intakes", :all_dbs do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:vha_predocket_workflow)
    FeatureToggle.enable!(:vha_predocket_appeals)
    bva_intake.add_user(bva_intake_user)
    camo.add_user(camo_user)
    program_office.add_user(program_office_user)
    regional_office.add_user(regional_office_user)
  end

  after do
    FeatureToggle.disable!(:vha_predocket_workflow)
    FeatureToggle.disable!(:vha_predocket_appeals)
  end

  let(:bva_intake) { BvaIntake.singleton }
  let!(:bva_intake_user) { create(:intake_user) }
  let(:camo) { VhaCamo.singleton }
  let(:camo_user) { create(:user) }
  let(:program_office) { create(:vha_program_office) }
  let(:program_office_user) { create(:user) }
  let(:regional_office) { create(:vha_regional_office) }
  let(:regional_office_user) { create(:user) }

  let(:veteran) { create(:veteran) }
  let(:po_instructions) { "Please look for this veteran's documents." }
  let(:ro_instructions) { "No docs here. Please look for this veteran's documents." }
  let(:ro_review_instructions) { "Look for PDFs of the decisions in the veteran's folder." }

  context "when a VHA case goes through intake" do
    before { OrganizationsUser.make_user_admin(bva_intake_user, bva_intake) }

    it "intaking VHA issues creates pre-docket tasks instead of regular docketing tasks" do
      step "BVA Intake user intakes a VHA case" do
        User.authenticate!(user: bva_intake_user)
        start_appeal(veteran, intake_user: bva_intake_user)
        visit "/intake"
        expect(page).to have_current_path("/intake/review_request")
        click_intake_continue
        expect(page).to have_content("Add / Remove Issues")

        click_intake_add_issue
        fill_in "Benefit type", with: "Veterans Health Administration"
        find("#issue-benefit-type").send_keys :enter
        fill_in "Issue category", with: "Caregiver"
        find("#issue-category").send_keys :enter
        fill_in "Issue description", with: "I am a VHA issue"
        fill_in "Decision date", with: 1.month.ago.mdY

        expect(page).to have_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
        safe_click ".add-issue"
        expect(page).to have_content(COPY::VHA_PRE_DOCKET_ADD_ISSUES_NOTICE)
        expect(page).to have_button("Submit appeal")
        click_intake_finish
        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")

        appeal = Appeal.last
        visit "/queue/appeals/#{appeal.external_id}"
        expect(page).to have_content("Pre-Docket")
      end

      step "Use can search the case and see the Pre Docketed status" do
        appeal = Appeal.last
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.veteran_file_number
        find("#submit-search-searchBarEmptyList").click
        expect(page).to have_content("Pre Docketed")
      end

      step "CAMO has appeal in queue with VhaDocumentSearchTask assigned" do
        appeal = Appeal.last
        User.authenticate!(user: camo_user)
        visit "/organizations/vha-camo?tab=inProgressTab"
        expect(page).to have_content("Assess Documentation")

        created_task_types = Set.new(appeal.tasks.map(&:type))
        pre_docket_tasks = Set.new %w[RootTask PreDocketTask VhaDocumentSearchTask]

        docket_tasks = Set.new %w[
          DistributionTask
          TrackVeteranTask
          InformalHearingPresentationTask
          EvidenceSubmissionWindowTask
          TranslationTask
        ]

        expect(pre_docket_tasks.subset?(created_task_types)).to be true
        expect(docket_tasks.subset?(created_task_types)).to be false
      end

      step "CAMO user assigns to Program Office" do
        User.authenticate!(user: camo_user)
        visit "/organizations/vha-camo?tab=inProgressTab"
        expect(page).to have_content(COPY::VHA_ASSESS_DOCUMENTATION_TASK_LABEL)

        find_link("#{veteran.name} (#{veteran.file_number})").click
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.label).click
        expect(page).to have_content(COPY::VHA_ASSIGN_TO_PROGRAM_OFFICE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_MODAL_BODY)
        find(".cf-select__control", text: COPY::VHA_PROGRAM_OFFICE_SELECTOR_PLACEHOLDER).click
        find("div", class: "cf-select__option", text: program_office.name).click
        fill_in("Provide instructions and context for this action:", with: po_instructions)
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_current_path("/organizations/#{camo.url}?tab=inProgressTab&page=1")
        expect(page).to have_content("Task assigned to #{program_office.name}")

        expect(AssessDocumentationTask.last).to have_attributes(
          type: "AssessDocumentationTask",
          status: Constants.TASK_STATUSES.assigned,
          assigned_by: camo_user,
          assigned_to_id: program_office.id
        )
      end

      step "Program Office has AssessDocumentationTask in queue" do
        User.authenticate!(user: program_office_user)
        visit "/queue"

        click_on("Switch views")
        click_on("#{program_office.name} team cases")

        expect(page).to have_current_path("/organizations/#{program_office.url}?tab=unassignedTab&page=1")
        expect(page).to have_content("Assess Documentation")

        find_link("#{veteran.name} (#{veteran.file_number})").click

        expect(page).to have_content("ASSIGNED TO\n#{program_office.name}")

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(po_instructions)
      end

      step "Program Office can mark an AssessDocumentationTask as in progress" do
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.label).click
        expect(page).to have_content(COPY::VHA_MARK_TASK_IN_PROGRESS_MODAL_TITLE)
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_current_path("/organizations/#{program_office.url}?tab=unassignedTab&page=1")
        expect(page).to have_content(COPY::VHA_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE)
      end

      step "Program Office can assign AssessDocumentationTask to Regional Office" do
        appeal = Appeal.last
        visit "/queue/appeals/#{appeal.external_id}"

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.label).click
        expect(page).to have_content(COPY::VHA_ASSIGN_TO_REGIONAL_OFFICE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_MODAL_BODY)
        find(".cf-select__control", text: COPY::VHA_REGIONAL_OFFICE_SELECTOR_PLACEHOLDER).click
        find("div", class: "cf-select__option", text: regional_office.name).click
        fill_in("Provide instructions and context for this action:", with: ro_instructions)
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_current_path("/organizations/#{program_office.url}?tab=unassignedTab&page=1")
        expect(page).to have_content("Task assigned to #{regional_office.name}")
      end

      step "Regional Office has AssessDocumentationTask in queue" do
        User.authenticate!(user: regional_office_user)
        visit "/queue"

        click_on("Switch views")
        click_on("#{regional_office.name} team cases")

        expect(page).to have_current_path("/organizations/#{regional_office.url}?tab=unassignedTab&page=1")
        expect(page).to have_content("Assess Documentation")

        find_link("#{veteran.name} (#{veteran.file_number})").click

        expect(page).to have_content("ASSIGNED TO\n#{regional_office.name}")

        first("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(ro_instructions)
      end

      step "Regional Office can mark an AssessDocumentationTask as in progress" do
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.label).click
        expect(page).to have_content(COPY::VHA_MARK_TASK_IN_PROGRESS_MODAL_TITLE)
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_current_path("/organizations/#{regional_office.url}?tab=unassignedTab&page=1")
        expect(page).to have_content(COPY::VHA_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE)
      end

      step "Regional Office can mark AssessDocumentationTask as Ready for Review" do
        appeal = Appeal.last
        visit "/queue/appeals/#{appeal.external_id}"

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: COPY::VHA_COMPLETE_TASK_LABEL).click
        expect(page).to have_content(COPY::VHA_COMPLETE_TASK_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_COMPLETE_TASK_MODAL_BODY)
        find("label", text: "VBMS").click
        fill_in(COPY::VHA_COMPLETE_TASK_MODAL_BODY, with: ro_review_instructions)
        find("button", class: "usa-button", text: "Submit").click
        expect(page).to have_content(COPY::VHA_COMPLETE_TASK_CONFIRMATION_VISN)

        appeal = Appeal.last
        visit "/queue/appeals/#{appeal.external_id}"
        find_all("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).first.click
        expect(page).to have_content("Documents for this appeal are stored in VBMS")
        expect(page).to have_content(ro_review_instructions)
      end

      step "CAMO can return the appeal to BVA Intake" do
        appeal = Appeal.last
        camo_task = VhaDocumentSearchTask.last
        bva_intake_task = PreDocketTask.last

        # Remove this section once the steps completing these tasks is available
        camo_task.children.each { |task| task.update!(status: "completed") }

        User.authenticate!(user: camo_user)
        visit "/queue/appeals/#{appeal.uuid}"
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_SEND_TO_BOARD_INTAKE.label).click

        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY)

        fill_in("Instructions:", with: "This appeal is ready to be docketed.")
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_CONFIRMATION.gsub("%s", appeal.veteran.person.name))
        expect(camo_task.reload.status).to eq Constants.TASK_STATUSES.completed
        expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.assigned
      end

      step "BVA Intake can docket an appeal" do
        appeal = Appeal.last
        camo_task = VhaDocumentSearchTask.last
        bva_intake_task = PreDocketTask.last

        User.authenticate!(user: bva_intake_user)
        visit "/queue/appeals/#{appeal.external_id}"
        bva_intake_dockets_appeal

        expect(page).to have_content(COPY::DOCKET_APPEAL_CONFIRMATION_TITLE)
        expect(page).to have_content(COPY::DOCKET_APPEAL_CONFIRMATION_DETAIL)
        expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.completed
        expect(camo_task.reload.status).to eq Constants.TASK_STATUSES.completed

        distribution_task = appeal.tasks.of_type(:DistributionTask).first
        docket_related_task = appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first

        expect(distribution_task.status).to eq Constants.TASK_STATUSES.on_hold
        expect(docket_related_task.status).to eq Constants.TASK_STATUSES.assigned
      end
    end

    # This test confirms that BVA Intake can still perform this action while tis
    # in progress and the Pre-Docket task is on hold.
    it "BVA Intake can manually docket an appeal without assessing documentation through Caseflow" do
      User.authenticate!(user: bva_intake_user)
      start_appeal(veteran, intake_user: bva_intake_user)
      visit "/intake"
      expect(page).to have_current_path("/intake/review_request")
      click_intake_continue
      expect(page).to have_content("Add / Remove Issues")

      click_intake_add_issue
      fill_in "Benefit type", with: "Veterans Health Administration"
      find("#issue-benefit-type").send_keys :enter
      fill_in "Issue category", with: "Caregiver"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "I am a VHA issue"
      fill_in "Decision date", with: 1.month.ago.mdY
      safe_click ".add-issue"
      expect(page).to have_button("Submit appeal")
      click_intake_finish
      expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")

      appeal = Appeal.last
      camo_task = VhaDocumentSearchTask.last
      bva_intake_task = PreDocketTask.last

      visit "/queue/appeals/#{appeal.external_id}"
      bva_intake_dockets_appeal

      expect(page).to have_content(COPY::DOCKET_APPEAL_CONFIRMATION_TITLE)
      expect(page).to have_content(COPY::DOCKET_APPEAL_CONFIRMATION_DETAIL)
      expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.completed
      expect(camo_task.reload.status).to eq Constants.TASK_STATUSES.cancelled

      distribution_task = appeal.tasks.of_type(:DistributionTask).first
      docket_related_task = appeal.tasks.of_type(:EvidenceSubmissionWindowTask).first

      expect(distribution_task.status).to eq Constants.TASK_STATUSES.on_hold
      expect(docket_related_task.status).to eq Constants.TASK_STATUSES.assigned
    end
  end

  def bva_intake_dockets_appeal
    expect(page).to have_content("Pre-Docket")

    find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.DOCKET_APPEAL.label).click

    expect(page).to have_content(COPY::DOCKET_APPEAL_MODAL_TITLE)
    expect(page).to have_content(COPY::DOCKET_APPEAL_MODAL_BODY)
    expect(page).to have_content(COPY::DOCKET_APPEAL_MODAL_NOTICE)

    find("button", class: "usa-button", text: "Confirm").click
  end
end
