# frozen_string_literal: true

describe PreDocketTask, :postgres do
  let(:appeal) { create(:appeal) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let!(:pre_docket_task) { create(:pre_docket_task, assigned_to: bva_intake) }
  let!(:assess_documentation_task) { create(:vha_document_search_task, parent: pre_docket_task) }
  let!(:education_documentation_search_task) { create(:education_document_search_task, parent: pre_docket_task) }
  let(:bva_intake) { BvaIntake.singleton }
  let!(:bva_intake_user) { create(:intake_user) }
  let!(:bva_intake_admin_user) { create(:intake_admin_user) }

  before do
    FeatureToggle.enable!(:docket_vha_appeals)
    bva_intake.add_user(bva_intake_user)
    bva_intake.add_user(bva_intake_admin_user)
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
  end

  after do
    FeatureToggle.disable!(:docket_vha_appeals)
  end

  describe ".label" do
    it "uses a friendly label" do
      expect(pre_docket_task.class.label).to eq COPY::PRE_DOCKET_TASK_LABEL
    end
  end

  describe "#available_actions" do
    subject { pre_docket_task.available_actions(user) }
    let(:user) { create(:user) }

    it { is_expected.to eq [] }

    context "When the user is a BVA Intake user" do
      let(:user) { bva_intake_user }

      it { is_expected.to eq pre_docket_task.available_actions(user) }
    end

    context "When the user is a BVA Intake admin" do
      let(:user) { bva_intake_admin_user }

      it { is_expected.to eq pre_docket_task.available_actions(user) }
    end

    context "When an admin user has the docket_vha_appeals FeatureToggle enabled" do
      before { FeatureToggle.enable!(:docket_vha_appeals) }
      after { FeatureToggle.disable!(:docket_vha_appeals) }

      let(:user) { bva_intake_admin_user }

      it { is_expected.to eq pre_docket_task.available_actions(user) }
    end
  end

  context "#docket_appeal" do
    it "Creates a distribution task and closes the pre-docket task" do
      expect { pre_docket_task.docket_appeal }.to_not raise_error
    end
  end

  context "#docket_appeal with docket_vha_appeals FeatureToggle enabled" do
    before { FeatureToggle.enable!(:docket_vha_appeals) }
    after { FeatureToggle.disable!(:docket_vha_appeals) }

    it "Creates a distribution task and closes the pre-docket task" do
      expect { pre_docket_task.docket_appeal }.to_not raise_error
    end
  end

  describe "#update_from_params" do
    subject { pre_docket_task.update_from_params(task_params, user) }

    let(:task_params) { { appeal: appeal, status: Constants.TASK_STATUSES.completed } }
    let(:user) { bva_intake_admin_user }

    context "If the task is being completed" do
      let(:task_params) { { appeal: appeal, status: Constants.TASK_STATUSES.completed } }

      it "Dockets the appeal and cancels any active children tasks" do
        subject

        expect(pre_docket_task.status).to eq Constants.TASK_STATUSES.completed
        distribution_task = appeal.tasks.of_type(:DistributionTask).first
        expect(distribution_task.status).to eq Constants.TASK_STATUSES.on_hold
        expect(assess_documentation_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end
  end
end
