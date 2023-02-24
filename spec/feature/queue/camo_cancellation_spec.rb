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
