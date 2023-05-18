# frozen_string_literal: true

RSpec.feature "Pre-Docket intakes", :all_dbs do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:vha_predocket_workflow)
    FeatureToggle.enable!(:visn_predocket_workflow)
    FeatureToggle.enable!(:docket_vha_appeals)

    bva_intake.add_user(bva_intake_user)
    camo.add_user(camo_user)
    emo.add_user(emo_user)
    program_office.add_user(program_office_user)
    regional_office.add_user(regional_office_user)
    education_rpo.add_user(education_rpo_user)
    vha_caregiver.add_user(vha_caregiver_user)
  end

  after do
    FeatureToggle.disable!(:vha_predocket_workflow)
    FeatureToggle.disable!(:visn_predocket_workflow)
    FeatureToggle.disable!(:docket_vha_appeals)
  end

  # Organizations
  let(:bva_intake) { BvaIntake.singleton }
  let(:camo) { VhaCamo.singleton }
  let(:camo_user) { create(:user) }
  let(:vha_caregiver) { VhaCaregiverSupport.singleton }
  let(:vha_caregiver_user) { create(:user) }
  let(:emo) { EducationEmo.singleton }
  let(:education_rpo) { create(:education_rpo) }
  let(:program_office) { create(:vha_program_office) }
  let(:regional_office) { create(:vha_regional_office) }
  let(:regional_office_user) { create(:user) }

  # Users
  let!(:bva_intake_user) { create(:intake_user) }
  let(:camo_user) { create(:user) }
  let(:vha_caregiver_user) { create(:user) }
  let(:emo_user) { create(:user) }
  let(:education_rpo_user) { create(:user) }
  let(:program_office_user) { create(:user) }
  let(:default_query_params) { "page=1&sort_by=typeColumn&order=asc" }
  let(:default_bva_query_params) { "page=1&sort_by=receiptDateColumn&order=asc" }

  let(:veteran) { create(:veteran) }
  let(:po_instructions) { "Please look for this veteran's documents." }
  let(:ro_instructions) { "No docs here. Please look for this veteran's documents." }
  let(:ro_review_instructions) { "Look for PDFs of the decisions in the veteran's folder." }

  context "when a VHA case goes through intake" do
    before { OrganizationsUser.make_user_admin(bva_intake_user, bva_intake) }

    context "Caregiver" do
      categories = Constants::ISSUE_CATEGORIES["vha"].grep(/Caregiver/)

      it "intaking VHA issues creates pre-docket tasks instead of regular docketing tasks" do
        step "BVA Intake user intakes a VHA case" do
          User.authenticate!(user: bva_intake_user)
          categories.each do |category|
            start_appeal(veteran, intake_user: bva_intake_user)
            visit "/intake"
            expect(page).to have_current_path("/intake/review_request")
            click_intake_continue
            expect(page).to have_content("Add / Remove Issues")

            click_intake_add_issue
            fill_in "Benefit type", with: "Veterans Health Administration"
            find("#issue-benefit-type").send_keys :enter
            fill_in "Issue category", with: category
            find("#issue-category").send_keys :enter
            fill_in "Issue description", with: "I am a VHA issue"
            fill_in "Decision date", with: 1.month.ago.mdY

            expect(page).to have_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
            safe_click ".add-issue"
            expect(page).to have_content(COPY::VHA_PRE_DOCKET_ADD_ISSUES_NOTICE)
            expect(page).to have_button("Submit appeal")
            click_intake_finish
            expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")

            vha_document_search_task = VhaDocumentSearchTask.last
            appeal = vha_document_search_task.appeal
            expect(vha_document_search_task.assigned_to).to eq vha_caregiver

            visit "/queue/appeals/#{appeal.external_id}"
            expect(page).to have_content("Pre-Docket")
            expect(page).to have_content(category)

            expect(page).to have_content(vha_caregiver.name)
          end
        end

        step "enacting the 'Mark task as in progress' task action updates
          the VhaDocumentSearchTask's status to in_progress" do
          User.authenticate!(user: vha_caregiver_user)

          vha_document_search_task = VhaDocumentSearchTask.last

          appeal = vha_document_search_task.appeal

          visit "/queue/appeals/#{appeal.external_id}"

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find(
            "div",
            class: "cf-select__option",
            text: Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS.label
          ).click

          expect(page).to have_content(COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_MODAL_TITLE)
          expect(page).to have_content(COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_MODAL_BODY)

          find("button", class: "usa-button", text: COPY::MODAL_MARK_TASK_IN_PROGRESS_BUTTON).click

          expect(page).to have_content(
            format(
              COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE,
              appeal.veteran_full_name
            )
          )
          in_progress_tab_name = VhaCaregiverSupportInProgressTasksTab.tab_name
          expected_url = "/organizations/#{vha_caregiver.url}?tab=#{in_progress_tab_name}&#{default_query_params}"
          expect(page).to have_current_path(expected_url)

          expect(vha_document_search_task.reload.status).to eq Constants.TASK_STATUSES.in_progress
        end

        step "enacting the 'Return to Board Intake' task action returns the task to BVA intake" do
          User.authenticate!(user: vha_caregiver_user)

          vha_document_search_task = VhaDocumentSearchTask.last

          appeal = vha_document_search_task.appeal

          visit "/queue/appeals/#{appeal.external_id}"

          task_name = Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE.label

          other_text_field_text = "Wrong type of documents"
          optional_text_field_text = "The documents included in the appeal are incorrect"

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find(
            "div",
            class: "cf-select__option",
            text: task_name
          ).click

          expect(page).to have_content(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TITLE)
          expect(page).to have_content(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_BODY)

          expect(page).to have_content(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_LABEL)
          expect(page).to have_content(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TEXT_FIELD_LABEL)

          # Fill in info and check for disabled submit button and warning text before submitting
          submit_button = find("button", class: "usa-button", text: COPY::MODAL_RETURN_BUTTON)

          expect(submit_button[:disabled]).to eq "true"

          # Open the searchable dropdown to view the options
          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT).click

          page_options = all("div.cf-select__option")
          page_options_text = page_options.map(&:text)
          controller_options = COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_OPTIONS
          controller_options = controller_options.values.pluck("LABEL")

          # Verify that all of the options are in the dropdown
          expect(page_options_text).to eq(controller_options)

          # Click the duplicate option and verify that the button is no longer disabled
          first_tested_option_text = controller_options.first
          find("div", class: "cf-select__option", text: first_tested_option_text).click
          expect(submit_button[:disabled]).to eq "false"

          # Check the other option functionality
          conditional_drop_down_text = COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_OPTIONS[
            "VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_OTHER"
          ]["LABEL"]

          # Reclick the dropdown with the new option and change it to "Other"
          find(".cf-select__control", text: first_tested_option_text).click
          find("div", class: "cf-select__option", text: conditional_drop_down_text).click

          # Verify the submit button is disabled again and check for the other reason text field
          expect(submit_button[:disabled]).to eq "true"
          expect(page).to have_content(
            COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_OTHER_REASON_TEXT_FIELD_LABEL
          )

          # Enter info into the optional text field and verify the submit button is still disabled
          fill_in(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TEXT_FIELD_LABEL,
                  with: optional_text_field_text)

          expect(submit_button[:disabled]).to eq "true"

          # Enter info into the other reason text field
          # Then verify that the submit button is no longer disabled before submitting
          fill_in(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_OTHER_REASON_TEXT_FIELD_LABEL,
                  with: other_text_field_text)

          expect(submit_button[:disabled]).to eq "false"

          submit_button.click

          expect(page).to have_content(
            format(
              COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_SUCCESS_CONFIRMATION,
              appeal.veteran_full_name
            )
          )

          completed_tab_name = VhaCaregiverSupportCompletedTasksTab.tab_name
          expected_url = "/organizations/#{vha_caregiver.url}?tab=#{completed_tab_name}&#{default_query_params}"
          expect(page).to have_current_path(expected_url)

          # Some quick data checks to verify that everything saved successfully
          expect(vha_document_search_task.reload.status).to eq Constants.TASK_STATUSES.completed
          expect(appeal.tasks.last.parent.assigned_to). to eq bva_intake
          expect(appeal.tasks.last.parent.status).to eq Constants.TASK_STATUSES.assigned

          # Navigate to the appeal that was just returned to board intake and verify the timeline
          visit "/queue/appeals/#{appeal.external_id}"
          # Click the timeline display link
          find(".cf-submit", text: "View task instructions").click
          # Verify the text in the timeline to match the other text field and optional text field.
          expect(page).to have_content("Other - #{other_text_field_text}")
          expect(page).to have_content(optional_text_field_text)
        end

        step "the 'Documents ready for Board Intake review' sends task to BVA Intake for review" do
          User.authenticate!(user: vha_caregiver_user)

          vha_document_search_task = VhaDocumentSearchTask.last
          vha_document_search_task.update!(status: Constants.TASK_STATUSES.assigned)

          appeal = vha_document_search_task.appeal

          visit "/queue/appeals/#{appeal.external_id}"

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find(
            "div",
            class: "cf-select__option",
            text: Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW.label
          ).click

          expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE)
          expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY)
          expect(page).to have_content("Optional")

          radio_choices = page.all(".cf-form-radio-option > label")
          expect(radio_choices[0]).to have_content("VBMS")
          expect(radio_choices[1]).to have_content("Centralized Mail Portal")
          expect(radio_choices[2]).to have_content("Other")

          radio_choices[0].click

          find("button", class: "usa-button", text: COPY::MODAL_SEND_BUTTON).click

          expect(page).to have_content(
            format(
              COPY::VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE,
              appeal.veteran_full_name
            )
          )

          completed_tab_name = VhaCaregiverSupportCompletedTasksTab.tab_name
          expected_url = "/organizations/#{vha_caregiver.url}?tab=#{completed_tab_name}&#{default_query_params}"
          expect(page).to have_current_path(expected_url)
          expect(vha_document_search_task.reload.status).to eq Constants.TASK_STATUSES.completed
        end

        step "BVA Intake user can return an appeal to CAREGIVER" do
          vha_document_search_task = VhaDocumentSearchTask.last
          vha_document_search_task.update!(status: Constants.TASK_STATUSES.completed)

          appeal = vha_document_search_task.appeal

          User.authenticate!(user: bva_intake_user)

          visit "/queue/appeals/#{appeal.uuid}"

          click_dropdown(text: Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.label)

          expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_CAREGIVER_MODAL_TITLE)
          expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_CAREGIVER_MODAL_BODY)

          instructions_textarea = find("textarea", id: "taskInstructions")
          instructions_textarea.send_keys("Please review this appeal, CAREGIVER.")

          find("button", text: COPY::MODAL_RETURN_BUTTON).click

          expect(page).to have_current_path("/organizations/#{bva_intake.url}?tab=pending&#{default_bva_query_params}")

          expect(page).to have_content(
            format(COPY::BVA_INTAKE_RETURN_TO_CAREGIVER_CONFIRMATION_TITLE, appeal.veteran_full_name)
          )

          expect(appeal.tasks.last.assigned_to). to eq vha_caregiver
        end

        step "BVA Intake user sees case in Ready for Review tab. They can docket appeal." do
          User.authenticate!(user: bva_intake_user)

          last_vha_task = VhaDocumentSearchTask.last
          last_vha_task.completed!

          visit "/organizations/bva-intake?tab=bvaReadyForReview"

          find_link("#{veteran.name} (#{veteran.file_number})").click

          click_dropdown(text: Constants.TASK_ACTIONS.DOCKET_APPEAL.label)

          expect(page).to have_content(
            format(COPY::DOCKET_APPEAL_MODAL_BODY, COPY::VHA_CAREGIVER_LABEL)
          )

          find("button", class: "usa-button", text: "Confirm").click
        end
      end
    end

    context "non caregiver" do
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
          fill_in "Issue category", with: "Beneficiary Travel"
          find("#issue-category").send_keys :enter
          fill_in "Issue description", with: "I am a VHA issue"
          fill_in "Decision date", with: 1.month.ago.mdY

          expect(page).to have_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
          safe_click ".add-issue"
          expect(page).to have_content(COPY::VHA_PRE_DOCKET_ADD_ISSUES_NOTICE)
          expect(page).to have_button("Submit appeal")
          click_intake_finish
          expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")

          vha_document_search_task = VhaDocumentSearchTask.last
          appeal = vha_document_search_task.appeal
          expect(vha_document_search_task.assigned_to).to eq camo

          visit "/queue/appeals/#{appeal.external_id}"
          expect(page).to have_content("Pre-Docket")

          expect(page).to have_content(camo.name)
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
          visit "/organizations/vha-camo?tab=camo_assigned"
          expect(page).to have_content(COPY::REVIEW_DOCUMENTATION_TASK_LABEL)

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
          visit "/organizations/vha-camo?tab=camo_assigned"
          expect(page).to have_content(COPY::REVIEW_DOCUMENTATION_TASK_LABEL)

          find_link("#{veteran.name} (#{veteran.file_number})").click
          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.label).click
          expect(page).to have_content(COPY::VHA_ASSIGN_TO_PROGRAM_OFFICE_MODAL_TITLE)
          expect(page).to have_content(COPY::PRE_DOCKET_MODAL_BODY)
          find(".cf-select__control", text: COPY::VHA_PROGRAM_OFFICE_SELECTOR_PLACEHOLDER).click
          find("div", class: "cf-select__option", text: program_office.name).click
          fill_in("Provide instructions and context for this action:", with: po_instructions)
          find("button", class: "usa-button", text: "Submit").click

          expect(page).to have_current_path("/organizations/#{camo.url}?tab=camo_assigned&#{default_query_params}")
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

          expect(page).to have_current_path("/organizations/#{program_office.url}"\
            "?tab=po_assigned&#{default_query_params}")
          expect(page).to have_content("Assess Documentation")

          find_link("#{veteran.name} (#{veteran.file_number})").click

          expect(page).to have_content("ASSIGNED TO\n#{program_office.name}")

          find("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          expect(page).to have_content(po_instructions)
        end

        step "Program Office can mark an AssessDocumentationTask as in progress" do
          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.label).click
          expect(page).to have_content(COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_MODAL_TITLE)
          find("button", class: "usa-button", text: "Submit").click

          expect(page).to have_current_path("/organizations/#{program_office.url}"\
            "?tab=po_assigned&#{default_query_params}")
          expect(page).to have_content(COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE)
        end

        step "Program Office can assign AssessDocumentationTask to Regional Office" do
          appeal = Appeal.last
          visit "/queue/appeals/#{appeal.external_id}"

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find(
            "div",
            class: "cf-select__option",
            text: Constants.TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.label
          ).click
          expect(page).to have_content(COPY::VHA_ASSIGN_TO_REGIONAL_OFFICE_MODAL_TITLE)
          expect(page).to have_content(COPY::PRE_DOCKET_MODAL_BODY)
          find(".cf-select__control", text: COPY::VHA_REGIONAL_OFFICE_SELECTOR_PLACEHOLDER).click
          find("div", class: "cf-select__option", text: regional_office.name).click
          fill_in("Provide instructions and context for this action:", with: ro_instructions)
          find("button", class: "usa-button", text: "Submit").click

          expect(page).to have_current_path("/organizations/#{program_office.url}"\
            "?tab=po_assigned&#{default_query_params}")
          expect(page).to have_content("Task assigned to #{regional_office.name}")
        end

        step "Regional Office has AssessDocumentationTask in queue" do
          User.authenticate!(user: regional_office_user)
          visit "/queue"

          click_on("Switch views")
          click_on("#{regional_office.name} team cases")

          expect(page).to have_current_path("/organizations/#{regional_office.url}"\
            "?tab=unassignedTab&#{default_query_params}")
          expect(page).to have_content("Assess Documentation")

          find_link("#{veteran.name} (#{veteran.file_number})").click

          expect(page).to have_content("ASSIGNED TO\n#{regional_office.name}")

          first("button", text: COPY::TASK_SNAPSHOT_VIEW_TASK_INSTRUCTIONS_LABEL).click
          expect(page).to have_content(ro_instructions)
        end

        step "Regional Office can mark an AssessDocumentationTask as in progress" do
          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.label).click
          expect(page).to have_content(COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_MODAL_TITLE)
          find("button", class: "usa-button", text: "Submit").click

          expect(page).to have_current_path("/organizations/#{regional_office.url}"\
            "?tab=unassignedTab&#{default_query_params}")
          expect(page).to have_content(COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE)
        end

        step "Regional Office can mark AssessDocumentationTask as Ready for Review" do
          appeal = Appeal.last
          visit "/queue/appeals/#{appeal.external_id}"

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find("div", class: "cf-select__option", text: COPY::VHA_COMPLETE_TASK_LABEL).click
          expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE)
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
          find(
            "div",
            class: "cf-select__option",
            text: Constants.TASK_ACTIONS.VHA_DOCUMENTS_READY_FOR_BVA_INTAKE_REVIEW.label
          ).click

          expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE)
          expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY)
          page.all(".cf-form-radio-option > label")[0].click
          find("button", class: "usa-button", text: COPY::MODAL_SEND_BUTTON).click

          expect(page).to have_content(
            COPY::VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE
            .gsub("%s", appeal.veteran.person.name)
          )
          expect(camo_task.reload.status).to eq Constants.TASK_STATUSES.completed
          expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.assigned
        end

        step "BVA Intake user can return an appeal to CAMO" do
          appeal = Appeal.last

          User.authenticate!(user: bva_intake_user)

          visit "/queue/appeals/#{appeal.uuid}"

          find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
          find(
            "div",
            class: "cf-select__option",
            text: Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.label
          ).click

          expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_CAMO_MODAL_TITLE)
          expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_CAMO_MODAL_BODY)

          instructions_textarea = find("textarea", id: "taskInstructions")
          instructions_textarea.send_keys("Please review this appeal, CAMO.")

          find("button", text: COPY::MODAL_SUBMIT_BUTTON).click

          expect(page).to have_current_path("/organizations/#{bva_intake.url}?tab=pending&#{default_bva_query_params}")

          expect(page).to have_content(
            format(COPY::BVA_INTAKE_RETURN_TO_CAMO_CONFIRMATION_TITLE, appeal.veteran_full_name)
          )

          expect(appeal.tasks.last.assigned_to). to eq camo
        end

        step "BVA Intake can docket an appeal" do
          appeal = Appeal.last
          camo_task = VhaDocumentSearchTask.last
          bva_intake_task = PreDocketTask.last

          camo_task.completed!

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

      # This test confirms that BVA Intake can still perform this action while it is
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
        fill_in "Issue category", with: "Beneficiary Travel"
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
  end

  def bva_intake_dockets_appeal
    expect(page).to have_content("Pre-Docket")

    find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
    find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.DOCKET_APPEAL.label).click

    expect(page).to have_content(COPY::DOCKET_APPEAL_MODAL_TITLE)
    expect(page).to have_content(format(COPY::DOCKET_APPEAL_MODAL_BODY, COPY::VHA_CAMO_LABEL))
    expect(page).to have_content(COPY::DOCKET_APPEAL_MODAL_NOTICE)

    find("button", class: "usa-button", text: "Confirm").click
  end

  context "when an education case goes through intake to be pre-docketed" do
    before do
      OrganizationsUser.make_user_admin(bva_intake_user, bva_intake)
      FeatureToggle.enable!(:edu_predocket_appeals)
      FeatureToggle.enable!(:docket_vha_appeals)
    end

    after do
      FeatureToggle.disable!(:edu_predocket_appeals)
      FeatureToggle.disable!(:docket_vha_appeals)
    end

    it "intaking Education issues and opting for pre-docket
      creates pre-docket tasks instead of regular docketing tasks" do
      step "BVA Intake user intakes a EMO case" do
        User.authenticate!(user: bva_intake_user)
        start_appeal(veteran, intake_user: bva_intake_user)

        visit "/intake"
        expect(page).to have_current_path("/intake/review_request")
        click_intake_continue
        expect(page).to have_content("Add / Remove Issues")

        click_intake_add_issue

        add_intake_nonrating_issue(
          benefit_type: "Education",
          category: "Accrued",
          description: "A pre-docketed education issue",
          date: 1.month.ago.mdY,
          is_predocket_needed: true
        )

        expect(page).to have_button("Submit appeal")
        click_intake_finish
        expect(page).to have_content("#{Constants.INTAKE_FORM_NAMES.appeal} has been submitted.")
      end

      step "User can search the case and see the Pre Docketed status" do
        appeal = Appeal.order("created_at").last
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.veteran_file_number
        find("#submit-search-searchBarEmptyList").click
        expect(page).to have_content("Pre Docketed")
      end

      step "EMO user can send appeal as Ready for Review" do
        User.authenticate!(user: emo_user)

        visit "/organizations/edu-emo?tab=education_emo_unassigned"
        expect(page).to have_content(COPY::REVIEW_DOCUMENTATION_TASK_LABEL)
        find_link("#{veteran.name} (#{veteran.file_number})").click

        expect(page).to have_content("Review Documentation")
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.EMO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.label
        ).click
        expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE)
        expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY)

        radio_choices = page.all(".cf-form-radio-option > label")
        expect(radio_choices[0]).to have_content("VBMS")
        expect(radio_choices[1]).to have_content("Centralized Mail Portal")
        expect(radio_choices[2]).to have_content("Other")

        radio_choices[0].click
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_content("You have successfully sent #{veteran.name}'s case to Board Intake for review")

        emo_task = EducationDocumentSearchTask.last
        bva_intake_task = PreDocketTask.last
        expect(emo_task.reload.status).to eq Constants.TASK_STATUSES.completed
        expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.assigned
      end
    end

    it "EMO & RPO Workflow" do
      appeal = create(:education_document_search_task, :assigned, assigned_by: bva_intake_user, assigned_to: emo).appeal

      step "EMO user assigns task to Regional Processing Office" do
        User.authenticate!(user: emo_user)
        visit "/organizations/edu-emo?tab=education_emo_unassigned"
        expect(page).to have_content(COPY::REVIEW_DOCUMENTATION_TASK_LABEL)

        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.EMO_ASSIGN_TO_RPO.label
        ).click
        expect(page).to have_content(COPY::EMO_ASSIGN_TO_RPO_MODAL_TITLE)
        expect(page).to have_content(COPY::PRE_DOCKET_MODAL_BODY)
        find(".cf-select__control", text: COPY::EDUCATION_RPO_SELECTOR_PLACEHOLDER).click

        find("div", class: "cf-select__option", text: education_rpo.name).click
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_current_path("/organizations/#{emo.url}"\
          "?tab=education_emo_unassigned&#{default_query_params}")
        expect(page).to have_content("Task assigned to #{education_rpo.name}")

        expect(EducationDocumentSearchTask.last).to have_attributes(
          type: "EducationDocumentSearchTask",
          status: Constants.TASK_STATUSES.on_hold,
          assigned_by: bva_intake_user,
          assigned_to_id: emo.id
        )

        expect(EducationAssessDocumentationTask.last).to have_attributes(
          type: "EducationAssessDocumentationTask",
          status: Constants.TASK_STATUSES.assigned,
          assigned_by: emo_user,
          assigned_to_id: education_rpo.id
        )
      end

      step "Task appears in EMO's assigned tab" do
        expect(page).to have_current_path("/organizations/edu-emo?tab=education_emo_unassigned&#{default_query_params}")
        find("button", text: COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE.split.first.chomp).click
        expect(page).to have_current_path("/organizations/edu-emo?tab=education_emo_assigned&#{default_query_params}")
        expect(page).to have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end

      step "RPO Task appears in RPO's assigned tab" do
        User.authenticate!(user: education_rpo_user)
        visit "/organizations/#{education_rpo.url}?tab=education_rpo_assigned&page=1"
        expect(page).to have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end

      step "RPO user marks task as in progress" do
        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click

        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.EDUCATION_RPO_MARK_TASK_IN_PROGRESS.label
        ).click

        expect(page).to have_content(COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_MODAL_TITLE)

        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_content(COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE)

        expect(EducationAssessDocumentationTask.last.status).to eq Constants.TASK_STATUSES.in_progress
      end

      step "RPO Task appears in RPO's in progress tab" do
        visit "/organizations/#{education_rpo.url}?tab=education_rpo_in_progress"
        expect(page).to have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end

      step "RPO user can send appeal to BVA Intake as Ready for Review" do
        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click
        rpo_task = EducationAssessDocumentationTask.last
        emo_task = EducationDocumentSearchTask.last
        bva_intake_task = PreDocketTask.last

        expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        expect(emo_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
        expect(rpo_task.reload.status).to eq Constants.TASK_STATUSES.in_progress

        find(class: "cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.EDUCATION_RPO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.label
        ).click
        expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE)
        expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY)

        radio_choices = page.all(".cf-form-radio-option > label")
        expect(radio_choices[0]).to have_content("VBMS")
        expect(radio_choices[1]).to have_content("Centralized Mail Portal")
        expect(radio_choices[2]).to have_content("Other")

        radio_choices[0].click
        find("button", class: "usa-button", text: "Submit").click

        expect(page).to have_content("You have successfully sent #{appeal.veteran.name}'s case to Board Intake")

        expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.assigned
        expect(emo_task.reload.status).to eq Constants.TASK_STATUSES.completed
        expect(rpo_task.reload.status).to eq Constants.TASK_STATUSES.completed
      end

      step "RPO user can find the appeal in the org's Completed Tab" do
        visit "/organizations/#{education_rpo.url}?tab=education_rpo_completed&page=1"
        expect(page).to have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end

      step "BVA Intake can find appeal in their Ready for Review Tab" do
        User.authenticate!(user: bva_intake_user)

        visit "/organizations/bva-intake?tab=bvaReadyForReview"
        expect(page).to have_content(COPY::PRE_DOCKET_TASK_LABEL)
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end

      step "BVA Intake's 'Docket appeal' modal contains org name for RPO" do
        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click

        click_dropdown(text: Constants.TASK_ACTIONS.DOCKET_APPEAL.label)

        expect(page).to have_content(
          format(COPY::DOCKET_APPEAL_MODAL_BODY, COPY::EDUCATION_LABEL)
        )
      end
    end

    it "EMO user can return an appeal to BVA Intake" do
      User.authenticate!(user: emo_user)
      appeal = create(:education_document_search_task, :assigned, assigned_to: emo).appeal

      step "EMO user can access the appeal in the EMO org unassigned queue tab" do
        visit "/organizations/edu-emo?tab=education_emo_unassigned"
        expect(page).to have_content(COPY::REVIEW_DOCUMENTATION_TASK_LABEL)
        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      end

      step "EMO user can select to return an appeal to BVA Intake" do
        expect(page).to have_content(COPY::REVIEW_DOCUMENTATION_TASK_LABEL)
        find(class: "cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.EMO_RETURN_TO_BOARD_INTAKE.label).click
        expect(page).to have_content(COPY::EMO_RETURN_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(page).to have_content(COPY::EMO_RETURN_TO_BOARD_INTAKE_MODAL_BODY)
      end

      step "If no text is entered into the modal's textarea it prevents submission" do
        find("button", class: "usa-button", text: COPY::MODAL_RETURN_BUTTON).click
        expect(page).to have_content(COPY::EMPTY_INSTRUCTIONS_ERROR)
      end

      step "After adding text to the text area the form can be submitted" do
        instructions_textarea = find("textarea", id: "emoReturnToBoardIntakeInstructions")
        instructions_textarea.send_keys("Issue was not related to education. Please reevalutate.")
        find("button", class: "usa-button", text: COPY::MODAL_RETURN_BUTTON).click
      end

      step "Task now appears in the EMO org's assigned tab" do
        expect(page).to have_current_path("/organizations/edu-emo?tab=education_emo_unassigned&#{default_query_params}")
        find("button", text: COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE.split.first.chomp).click
        expect(page).to have_current_path("/organizations/edu-emo?tab=education_emo_assigned&#{default_query_params}")
        expect(page).to have_content(COPY::PRE_DOCKET_TASK_LABEL)
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end

      step "Switch to BVA Intake user and make sure task appears in the BVA Intake org's Ready for Review tab" do
        User.authenticate!(user: bva_intake_user)
        visit "/organizations/bva-intake?tab=bvaReadyForReview"
        expect(page).to have_content(COPY::PRE_DOCKET_TASK_LABEL)
        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click
      end

      step "Send the appeal back to the EMO" do
        find(class: "cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.label).click
        expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_EMO_MODAL_TITLE)
        expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_EMO_MODAL_BODY)

        instructions_textarea = find("textarea", id: "taskInstructions")
        instructions_textarea.send_keys("The intake details have been corrected. Please review this appeal.")

        find("button", class: "usa-button", text: COPY::MODAL_SUBMIT_BUTTON).click
      end

      step "Switch to an EMO user and make sure the active
        EducationDocumentSearchTask only appears in the unassigned tab" do
        User.authenticate!(user: emo_user)
        visit "/organizations/edu-emo?tab=education_emo_unassigned"
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")

        find("button", text: COPY::ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE.split.first.chomp).click
        expect(page).to_not have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end
    end

    it "RPO user can return an appeal to the EMO" do
      appeal = create(
        :education_assess_documentation_task,
        :assigned,
        assigned_to: education_rpo,
        assigned_by: emo_user
      ).appeal

      step "RPO user navigates to the appeal's queue page and returns it to the EMO" do
        User.authenticate!(user: education_rpo_user)

        visit "/organizations/#{education_rpo.url}?tab=education_rpo_assigned&page=1"
        expect(page).to have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)

        find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find(
          "div",
          class: "cf-select__option",
          text: Constants.TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.label
        ).click

        expect(page).to have_content(COPY::EDUCATION_RPO_RETURN_TO_EMO_MODAL_TITLE)
        expect(page).to have_content(COPY::PRE_DOCKET_MODAL_BODY)

        find("button", text: COPY::MODAL_RETURN_BUTTON).click
        expect(page).to have_content(COPY::INSTRUCTIONS_ERROR_FIELD_REQUIRED)

        instructions_textarea = find("textarea", id: "taskInstructions")
        instructions_textarea.send_keys("Incorrect RPO. Please review.")
        find("button", class: "usa-button-secondary", text: COPY::MODAL_RETURN_BUTTON).click

        expect(page).to have_current_path(
          "/organizations/#{education_rpo.url}?tab=education_rpo_assigned&#{default_query_params}"
        )
      end

      step "Task is now cancelled, and does not show up in any of the RPOs queue tabs" do
        expect(EducationDocumentSearchTask.last).to have_attributes(
          type: "EducationDocumentSearchTask",
          status: Constants.TASK_STATUSES.assigned,
          assigned_to_id: emo.id
        )

        expect(EducationAssessDocumentationTask.last).to have_attributes(
          type: "EducationAssessDocumentationTask",
          status: Constants.TASK_STATUSES.cancelled,
          assigned_by: emo_user,
          assigned_to_id: education_rpo.id
        )

        visit "/organizations/#{education_rpo.url}?tab=education_rpo_assigned"
        expect(page).to_not have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)

        visit "/organizations/#{education_rpo.url}?tab=education_rpo_in_progress"
        expect(page).to_not have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)

        visit "/organizations/#{education_rpo.url}?tab=education_rpo_completed"
        expect(page).to_not have_content(COPY::ASSESS_DOCUMENTATION_TASK_LABEL)
      end

      step "Task returned to the EMO shows up in the EMO's unassigned tab" do
        User.authenticate!(user: emo_user)
        visit "/organizations/edu-emo?tab=education_emo_unassigned"
        expect(page).to have_content("#{appeal.veteran.name} (#{appeal.veteran.file_number})")
      end
    end

    it "RPO user can send appeal to BVA Intake as Ready for Review
      even if another RPO had previously cancelled a task" do
      emo_task = create(:education_document_search_task, :assigned, assigned_to: emo)
      bva_intake_task = PreDocketTask.last
      appeal = emo_task.appeal

      # Add a cancelled task onto emo_task to represent an instance where an RPO sent an appeal back to the EMO.
      EducationAssessDocumentationTask.create!(
        parent: emo_task,
        appeal: appeal,
        assigned_at: Time.zone.now,
        assigned_to: education_rpo
      ).cancelled!

      open_rpo_task = EducationAssessDocumentationTask.create!(
        parent: emo_task,
        appeal: appeal,
        assigned_at: Time.zone.now,
        assigned_to: education_rpo
      )

      User.authenticate!(user: education_rpo_user)

      visit "/organizations/#{education_rpo.url}?tab=education_rpo_assigned"
      find_link("#{appeal.veteran.name} (#{appeal.veteran.file_number})").click

      expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
      expect(emo_task.reload.status).to eq Constants.TASK_STATUSES.on_hold
      expect(open_rpo_task.reload.status).to eq Constants.TASK_STATUSES.assigned

      find(class: "cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find(
        "div",
        class: "cf-select__option",
        text: Constants.TASK_ACTIONS.EDUCATION_RPO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.label
      ).click
      expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE)
      expect(page).to have_content(COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_BODY)

      radio_choices = page.all(".cf-form-radio-option > label")
      expect(radio_choices[0]).to have_content("VBMS")
      expect(radio_choices[1]).to have_content("Centralized Mail Portal")
      expect(radio_choices[2]).to have_content("Other")

      radio_choices[0].click
      find("button", class: "usa-button", text: "Submit").click

      expect(page).to have_content("You have successfully sent #{appeal.veteran.name}'s case to Board Intake")

      expect(bva_intake_task.reload.status).to eq Constants.TASK_STATUSES.assigned
      expect(emo_task.reload.status).to eq Constants.TASK_STATUSES.completed
      expect(open_rpo_task.reload.status).to eq Constants.TASK_STATUSES.completed
    end

    it "BVA Intake user can return an appeal to the EMO" do
      emo_task = create(
        :education_document_search_task,
        :assigned,
        assigned_to: emo,
        assigned_by: bva_intake_user
      )

      emo_task.completed!

      User.authenticate!(user: bva_intake_user)

      visit "/queue/appeals/#{emo_task.appeal.uuid}"

      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find(
        "div",
        class: "cf-select__option",
        text: Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.label
      ).click

      expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_EMO_MODAL_TITLE)
      expect(page).to have_content(COPY::BVA_INTAKE_RETURN_TO_EMO_MODAL_BODY)

      instructions_textarea = find("textarea", id: "taskInstructions")
      instructions_textarea.send_keys("Please review this appeal, EMO.")

      find("button", text: COPY::MODAL_SUBMIT_BUTTON).click

      expect(page).to have_current_path("/organizations/#{bva_intake.url}?tab=pending&#{default_bva_query_params}")

      expect(page).to have_content(
        format(COPY::BVA_INTAKE_RETURN_TO_EMO_CONFIRMATION_TITLE, emo_task.appeal.veteran_full_name)
      )

      expect(emo_task.appeal.tasks.last.assigned_to). to eq emo
    end

    it "BVA Intake's 'Docket appeal' modal contains correct org name" do
      User.authenticate!(user: bva_intake_user)

      # Complete new task to send it back to BVA Intake
      emo_task = create(:education_document_search_task, :assigned, assigned_to: emo)
      emo_task.completed!

      visit "/queue/appeals/#{emo_task.appeal.uuid}"

      click_dropdown(text: Constants.TASK_ACTIONS.DOCKET_APPEAL.label)

      expect(page).to have_content(
        format(COPY::DOCKET_APPEAL_MODAL_BODY, COPY::EDUCATION_LABEL)
      )
    end
  end
end
