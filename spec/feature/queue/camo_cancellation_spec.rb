# frozen_string_literal: true

RSpec.feature "CAMO can recommend cancellation to BVA Intake", :all_dbs do
  let(:camo_org) { VhaCamo.singleton }
  let(:camo_user) { create(:user, full_name: "Camo User", css_id: "CAMOUSER") }
  let(:bva_intake_org) { BvaIntake.singleton }
  let!(:bva_intake_user) { create(:intake_user) }
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
  let!(:appeal) { Appeal.find(task.appeal_id) }

  before do
    FeatureToggle.enable!(:vha_predocket_workflow)
    FeatureToggle.enable!(:vha_irregular_appeals)
    camo_org.add_user(camo_user)
    bva_intake_org.add_user(bva_intake_user)
  end

  after do
    FeatureToggle.disable!(:vha_predocket_workflow)
    FeatureToggle.disable!(:vha_irregular_appeals)
  end

  context "CAMO user can assign a case to BVA intake, recommending cancellation" do
    before do
      User.authenticate!(user: camo_user)
    end
    scenario "assign to BVA intake" do
      step "navigate from CAMO team queue to case details" do
        visit camo_org.path
        click_on "#{appeal.veteran_full_name} (#{appeal.veteran_file_number})"
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
        expect(page).to have_content(appeal.veteran_full_name.to_s)
      end
      step "trigger send to board intake modal" do
        find(".cf-select__control", text: COPY::TASK_ACTION_DROPDOWN_BOX_LABEL).click
        find("div", class: "cf-select__option", text: Constants.TASK_ACTIONS.VHA_SEND_TO_BOARD_INTAKE.label).click
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_DETAIL)
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY)
      end
      step "trigger error state" do
        find("button", class: "usa-button", text: "Submit").click
        expect(page).to have_content(COPY::SELECT_RADIO_ERROR)
        expect(page).to have_content(COPY::EMPTY_INSTRUCTIONS_ERROR)
      end
      step "submit valid form" do
        find("label", text: COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_NOT_APPEALABLE).click
        fill_in("Provide additional context and/or documents:", with: "This should be cancelled.")
        find("button", class: "usa-button", text: "Submit").click
      end
      step "redirect and confirmation" do
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_CONFIRMATION.gsub("%s", appeal.veteran.person.name))
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
end
