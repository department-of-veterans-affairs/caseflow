# frozen_string_literal: true

describe PreDocketTask, :postgres do
  let(:appeal) { create(:appeal) }
  let(:root_task) { create(:root_task, appeal: appeal) }
  let!(:pre_docket_task) { create(:pre_docket_task, assigned_to: bva_intake) }
  let(:bva_intake) { BvaIntake.singleton }
  let!(:bva_intake_user) { create(:intake_user) }
  let!(:bva_intake_admin_user) { create(:intake_admin_user) }

  before do
    bva_intake.add_user(bva_intake_user)
    bva_intake.add_user(bva_intake_admin_user)
    OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
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

      context "emo task" do
        let(:emo_task) do
          EducationDocumentSearchTask.create!(
            appeal: pre_docket_task.appeal,
            parent: pre_docket_task,
            assigned_at: Time.zone.now,
            assigned_to: EducationEmo.singleton
          )
        end

        it { is_expected.to eq pre_docket_task.available_actions(user) }

        it "they cannot return an appeal to an organization that already has it" do
          is_expected.to include Constants.TASK_ACTIONS.DOCKET_APPEAL.to_h
          is_expected.to_not include Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.to_h
        end

        it "they can return an appeal to an organization once that org has closed their task" do
          emo_task.completed!
          is_expected.to include Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.to_h
        end
      end

      context "camo task" do
        let(:camo_task) do
          VhaDocumentSearchTask.create!(
            appeal: pre_docket_task.appeal,
            parent: pre_docket_task,
            assigned_at: Time.zone.now,
            assigned_to: VhaCamo.singleton
          )
        end

        it { is_expected.to eq pre_docket_task.available_actions(user) }

        it "they cannot return an appeal to an organization that already has it" do
          is_expected.to include Constants.TASK_ACTIONS.DOCKET_APPEAL.to_h
          is_expected.to_not include Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.to_h
        end

        it "they can return an appeal to an organization once that org has closed their task" do
          camo_task.completed!
          is_expected.to include Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.to_h
        end
      end

      context "caregiver task" do
        let(:vha_caregiver_task) do
          VhaDocumentSearchTask.create!(
            appeal: pre_docket_task.appeal,
            parent: pre_docket_task,
            assigned_at: Time.zone.now,
            assigned_to: VhaCaregiverSupport.singleton
          )
        end

        it { is_expected.to eq pre_docket_task.available_actions(user) }

        it "they cannot return an appeal to an organization that already has it" do
          is_expected.to include Constants.TASK_ACTIONS.DOCKET_APPEAL.to_h
          is_expected.to_not include Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.to_h
        end

        it "they can return an appeal to an organization once that org has closed their task" do
          vha_caregiver_task.completed!
          is_expected.to include Constants.TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.to_h
        end
      end
    end
  end

  context "#docket_appeal" do
    let!(:pre_docket_task) { create(:pre_docket_task, assigned_to: bva_intake) }
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
    before { FeatureToggle.enable!(:docket_vha_appeals) }
    after { FeatureToggle.disable!(:docket_vha_appeals) }

    subject { pre_docket_task.update_from_params(task_params, user) }

    let!(:document_search_task) { create(:vha_document_search_task, parent: pre_docket_task) }
    let(:task_params) { { appeal: appeal, status: Constants.TASK_STATUSES.completed } }
    let(:user) { bva_intake_admin_user }

    context "If the task is being completed" do
      let(:task_params) { { appeal: appeal, status: Constants.TASK_STATUSES.completed } }

      it "Dockets the appeal and cancels any active children tasks" do
        subject

        expect(pre_docket_task.status).to eq Constants.TASK_STATUSES.completed
        distribution_task = appeal.tasks.of_type(:DistributionTask).first
        expect(distribution_task.status).to eq Constants.TASK_STATUSES.on_hold
        expect(document_search_task.reload.status).to eq Constants.TASK_STATUSES.cancelled
      end
    end
  end
end
