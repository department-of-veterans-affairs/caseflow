# frozen_string_literal: true

describe VhaDocumentSearchTask, :postgres do
  let(:task) { create(:vha_document_search_task) }
  let(:camo) { VhaCamo.singleton }
  let(:user) { create(:user) }

  before { camo.add_user(user) }

  describe ".label" do
    before { FeatureToggle.enable!(:vha_predocket_workflow) }
    after { FeatureToggle.disable!(:vha_predocket_workflow) }
    it "uses a friendly label" do
      expect(task.class.label).to eq COPY::REVIEW_DOCUMENTATION_TASK_LABEL
    end
  end

  shared_examples "whenever the vha_predocket_workflow FeatureToggle is disabled" do
    before { FeatureToggle.disable!(:vha_predocket_workflow) }

    it "available actions are empty" do
      is_expected.to match_array []
    end
  end

  shared_examples "whenever the user is not part of the organization the task is assigned to" do
    before { BvaIntake.singleton.add_user(non_org_user) }
    let(:non_org_user) { create(:user) }

    subject { task.available_actions(non_org_user) }

    it "available actions are empty" do
      is_expected.to match_array []
    end
  end

  describe "#available_actions" do
    before { FeatureToggle.enable!(:vha_predocket_workflow) }
    after { FeatureToggle.disable!(:vha_predocket_workflow) }

    subject { task.available_actions(user) }

    context "whenever the VhaDocumentSearchTask is assigned to VHA CAMO" do
      let(:task) { create(:vha_document_search_task, assigned_to: camo) }

      it "all potential VHA CAMO actions are available" do
        is_expected.to eq VhaDocumentSearchTask::VHA_CAMO_TASK_ACTIONS
      end

      it_behaves_like "whenever the vha_predocket_workflow FeatureToggle is disabled"
      it_behaves_like "whenever the user is not part of the organization the task is assigned to"
    end

    context "whenever the VhaDocumentSearchTask is assigned to VHA Caregiver Support" do
      before { csp.add_user(user) }

      let(:csp) { VhaCaregiverSupport.singleton }
      let(:user) { create(:user) }

      subject { task.available_actions(user) }

      context "whenever the task has a status of assigned" do
        let(:task) do
          create(:vha_document_search_task, assigned_to: csp, status: Constants.TASK_STATUSES.assigned)
        end

        it "all potential actions are available" do
          is_expected.to match_array(
            [Constants.TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS.to_h] +
            VhaDocumentSearchTask::VHA_CAREGIVER_SUPPORT_TASK_ACTIONS
          )
        end

        it_behaves_like "whenever the vha_predocket_workflow FeatureToggle is disabled"
        it_behaves_like "whenever the user is not part of the organization the task is assigned to"
      end

      context "whenever the task has a status of in progress" do
        before { task.update(status: Constants.TASK_STATUSES.in_progress) }

        let(:task) do
          create(:vha_document_search_task, assigned_to: csp)
        end

        it "in progress action is not available, but the others are" do
          is_expected.to match_array VhaDocumentSearchTask::VHA_CAREGIVER_SUPPORT_TASK_ACTIONS
        end

        it_behaves_like "whenever the vha_predocket_workflow FeatureToggle is disabled"
        it_behaves_like "whenever the user is not part of the organization the task is assigned to"
      end
    end
  end
end
