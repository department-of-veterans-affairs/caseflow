# frozen_string_literal: true

RSpec.feature "CAMO can recommend cancellation to BVA Intake", :all_dbs do
  let(:camo_org) { VhaCamo.singleton }
  let(:camo_user) { create(:user, full_name: "Camo User", css_id: "CAMOUSER") }
  let(:bva_intake_org) { BvaIntake.singleton }
  let!(:bva_intake_user) { create(:intake_user) }
  let(:vha_po_org) { VhaProgramOffice.create!(name: "Vha Program Office", url: "po-vha-test") }
  let(:vha_po_user) { create(:user, full_name: "PO User", css_id: "POUSER") }

  let!(:task) do
    create(
      :vha_document_search_task,
      :assigned,
      assigned_to: camo_org,
      parent: create(:pre_docket_task,
                     appeal: create(:appeal, :with_vha_issue),
                     assigned_to: bva_intake_org)
    )
  end
  let!(:po_task) do
    create(
      :assess_documentation_task,
      :in_progress,
      assigned_to: vha_po_org
    )
  end
  let!(:appeal) { Appeal.find(task.appeal_id) }

  before do
    FeatureToggle.enable!(:vha_predocket_workflow)
    FeatureToggle.enable!(:vha_irregular_appeals)
    camo_org.add_user(camo_user)
    bva_intake_org.add_user(bva_intake_user)
    vha_po_org.add_user(vha_po_user)
  end

  after do
    FeatureToggle.disable!(:vha_predocket_workflow)
    FeatureToggle.disable!(:vha_irregular_appeals)
  end

  context "CAMO user can return a case to BVA intake" do
    before do
      User.authenticate!(user: camo_user)
    end
    scenario "assign to BVA intake" do
      navigate_from_camo_queue_to_case_details
      step "trigger return to board intake modal" do
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_RETURN_TO_BOARD_INTAKE.label).click
        expect(page).to have_content(COPY::VHA_RETURN_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_RETURN_TO_BOARD_INTAKE_MODAL_DETAIL)
        expect(page).to have_content(COPY::VHA_RETURN_TO_BOARD_INTAKE_MODAL_BODY)
      end
      step "submit valid form" do
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL_SHORT).click
        find(
          "div",
          class: "cf-select__option",
          text: COPY::VHA_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_OPTIONS["DUPLICATE"]["LABEL"]
        ).click
        fill_in("Provide additional context for this action", with: "This is a duplicate of 1234567.")
        find("button", class: "usa-button", text: COPY::MODAL_RETURN_BUTTON).click
      end
      step "redirect and confirmation" do
        expect(page).to have_content(COPY::VHA_RETURN_TO_BOARD_INTAKE_CONFIRMATION
          .gsub("%s", appeal.veteran.person.name))
      end
    end
  end

  context "BVA Intake user has appeal in queue" do
    before do
      User.authenticate!(user: bva_intake_user)
    end
    scenario "navigate to queue and confirm appeal is there" do
      visit bva_intake_org.path
      expect(page).to have_content("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
    end
  end

  context "PO to Camo Cancellation Flow" do
    before do
      User.authenticate!(user: vha_po_user)
    end

    scenario "assign to VHA CAMO" do
      visit vha_po_org.path
      # navigate_from_camo_queue_to_case_details
      reload_case_detail_page(po_task.appeal.uuid)
      find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
      find(
        "div",
        class: "cf-select__option",
        text: Constants.TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.label
      ).click
      expect(page).to have_content(COPY::VHA_PROGRAM_OFFICE_RETURN_TO_CAMO_MODAL_TITLE)
      expect(page).to have_content(COPY::VHA_CANCEL_TASK_INSTRUCTIONS_LABEL)
      fill_in("taskInstructions", with: "Testing this Cancellation flow")
      find("button", class: "usa-button", text: COPY::MODAL_RETURN_BUTTON).click

      expect(page).to have_current_path("#{vha_po_org.path}?tab=po_assigned&page=1&sort_by=typeColumn&order=asc")
      expect(page).to have_content(COPY::VHA_PROGRAM_OFFICE_RETURN_TO_CAMO_CONFIRMATION_TITLE)
      expect(page).to have_content(COPY::VHA_PROGRAM_OFFICE_RETURN_TO_CAMO_CONFIRMATION_DETAIL)

      po_task.reload
      expect(po_task.status).to eq "cancelled"
    end
  end

  private

  def navigate_from_camo_queue_to_case_details
    step "navigate from CAMO team queue to case details" do
      visit camo_org.path
      click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      expect(page).to have_content(appeal.veteran_full_name.to_s)
    end
  end
end
