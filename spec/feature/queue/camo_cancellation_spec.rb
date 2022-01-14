# frozen_string_literal: true

RSpec.feature "CAMO can recommend cancellation to BVA Intake", :all_dbs do
  let(:camo_org) { VhaCamo.singleton }
  let(:camo_user) { create(:user, full_name: "Camo User", css_id: "CAMOUSER") }
  let(:bva_org) { BvaIntake.singleton }
  let(:bva_user) { create(:user) }
  let!(:task) do
    create(
      :vha_document_search_task,
      :assigned,
      assigned_to: camo_org,
      appeal: create(:appeal)
    )
  end
  let!(:appeal) { Appeal.find(task.appeal_id) }

  before do
    FeatureToggle.enable!(:vha_predocket_appeals)
    FeatureToggle.enable!(:vha_predocket_workflow)
    FeatureToggle.enable!(:vha_irregular_appeals)
    camo_org.add_user(camo_user)
    bva_org.add_user(bva_user)
  end

  after do
    FeatureToggle.disable!(:vha_predocket_appeals)
    FeatureToggle.disable!(:vha_predocket_workflow)
    FeatureToggle.disable!(:vha_irregular_appeals)
  end

  # Assign to BVA intake
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
      step "perform send to board intake action" do
        safe_click ".cf-select"
        click_dropdown(text: COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_TITLE)
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_DETAIL)
        expect(page).to have_content(COPY::VHA_SEND_TO_BOARD_INTAKE_MODAL_BODY)
        # TODO: fill out and submit
      end
      step "redirect and confirmation" do
        # TODO: check for redirect to assign tab of team queue
        # TODO: check for success message
      end
    end
  end

  # Confirm in BVA queue
  context "BVA Intake user has appeal in queue" do
    before do
      User.authenticate!(user: bva_user)
    end
    scenario "navigate to queue and confirm appeal is there" do
      visit bva_org.path
      expect(page).to have_content("#{appeal.veteran_full_name} (#{appeal.veteran_file_number})")
    end
  end
end
