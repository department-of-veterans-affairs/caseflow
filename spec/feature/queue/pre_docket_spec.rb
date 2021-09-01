# frozen_string_literal: true

RSpec.feature "Pre-Docket intakes", :all_dbs do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:vha_predocket_appeals)
    bva_intake.add_user(bva_intake_user)
    camo.add_user(camo_user)
    program_office.add_user(program_office_user)
    regional_office.add_user(regional_office_user)
  end

  after { FeatureToggle.disable!(:vha_predocket_appeals) }

  let(:bva_intake) { BvaIntake.singleton }
  let(:bva_intake_user) { create(:intake_user) }
  let(:camo) { VhaCamo.singleton }
  let(:camo_user) { create(:user) }
  let(:program_office) { create(:vha_program_office) }
  let(:program_office_user) { create(:user) }
  let(:regional_office) { create(:vha_regional_office) }
  let(:regional_office_user) { create(:user) }

  let(:veteran) { create(:veteran) }
  let(:po_instructions) { "Please look for this veteran's documents." }
  let(:ro_instructions) { "No docs here. Please look for this veteran's documents." }

  context "when a VHA case goes through intake" do
    it "intaking VHA issues creates pre-docket tasks instead of regular docketing tasks" do
      step "BVA Intake user intakes a VHA case" do
        User.authenticate!(user: bva_intake_user)
        start_appeal(veteran, intake_user: bva_intake_user)
        visit "/intake"

        expect(page).to have_current_path("/intake/review_request")

        click_intake_continue

        expect(page).to have_content("Add / Remove Issues")

        click_intake_add_issue
        add_intake_nonrating_issue(
          benefit_type: "Veterans Health Administration",
          category: "Caregiver",
          description: "I am a VHA issue",
          date: 1.month.ago.mdY
        )
        click_intake_finish
        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
        appeal = Appeal.last
        visit "/queue/appeals/#{appeal.external_id}"
        expect(page).to have_content("Pre Docket Task")
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
        expect(page).to have_content("Assess Documentation Task")

        find_link("#{veteran.name} (#{veteran.file_number})").click

        expect(page).to have_content("ASSIGNED TO\n#{program_office.name}")

        find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(po_instructions)
      end

      step "Program Office can assign AssessDocumentationTask to Regional Office" do
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
        expect(page).to have_content("Assess Documentation Task")

        find_link("#{veteran.name} (#{veteran.file_number})").click

        expect(page).to have_content("ASSIGNED TO\n#{regional_office.name}")

        first("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
        expect(page).to have_content(ro_instructions)
      end
    end
  end
end
