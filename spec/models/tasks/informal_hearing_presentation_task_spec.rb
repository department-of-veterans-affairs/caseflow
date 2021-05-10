# frozen_string_literal: true

describe InformalHearingPresentationTask, :postgres do
  let(:user) { create(:user, roles: ["VSO"]) }

  describe ".available_actions" do
    subject { task.available_actions(user) }

    context "when task is assigned to user" do
      let(:task) do
        InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task, assigned_to: user).id)
      end

      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      it "should return team assign, person reassign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to an organization the user is a member of" do
      let(:org) { Organization.find(create(:organization).id) }
      let(:task) do
        InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task, assigned_to: org).id)
      end
      let(:expected_actions) do
        [
          Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      before { allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true) }
      it "should return team assign, person assign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to another user in organization the user is an admin of" do
      let(:org) { create(:organization) }
      let(:another_user) { create(:user, roles: ["VSO"]) }
      let(:org_task) { create(:informal_hearing_presentation_task, assigned_to: org) }
      let(:task) { create(:informal_hearing_presentation_task, assigned_to: another_user, parent: org_task) }
      let(:expected_actions) { [Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h] }

      before do
        allow_any_instance_of(Organization).to receive(:user_has_access?).and_return(true)
        OrganizationsUser.make_user_admin(user, org)
      end

      it "should return team reassign action" do
        expect(subject).to eq(expected_actions)
      end
    end

    context "when task is assigned to user" do
      let(:task) do
        InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task).id)
      end

      let(:expected_actions) do
        []
      end

      it "should return team assign, person reassign, and mark complete actions" do
        expect(subject).to eq(expected_actions)
      end
    end
  end

  describe ".when poa is updated" do
    context "change IHP task from old POA to new POA" do
      let(:appeal) { create(:appeal, veteran: create(:veteran)) }
      let(:vso) { create(:vso) }
      let(:claimant_participant_id) { "874639021" }
      # let!(:old_poa) { create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id) }
      let!(:new_poa) { create(:bgs_power_of_attorney, claimant_participant_id: claimant_participant_id) }
      let(:new_ihp_org_task) do
        create(
          :informal_hearing_presentation_task,
          appeal: appeal,
          assigned_to: vso
        )
      end

      it "automatically updates IHP to new poa" do
        new_poa.save_with_updated_bgs_record!
        InformalHearingPresentationTask.update_to_new_poa(appeal)
        expect(appeal.power_of_attorney.poa_participant_id).to eq new_poa.poa_participant_id
      end
    end
  end

  describe "when an IHP task is cancelled" do
    let(:appeal) { create(:appeal) }
    let(:task) do
      InformalHearingPresentationTask.find(create(:informal_hearing_presentation_task, assigned_to: user).id)
    end

    before do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end

    it "should create a DistributionTask" do
      task.update!(status: Constants.TASK_STATUSES.cancelled)
      expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      expect(appeal.root_task.reload.children.count { |t| t.type == DistributionTask.name }).to eq(1)
    end
  end

  describe "#update_from_params" do
    subject { task.update_from_params(params, user) }

    let(:organization) { create(:organization) }
    let(:user) { create(:user).tap { |org_user| organization.add_user(org_user) } }
    let(:appeal) { create(:appeal) }
    let(:task) { create(:informal_hearing_presentation_task, assigned_to: organization, appeal: appeal) }
    let(:params) { { status: Constants.TASK_STATUSES.completed } }

    before do
      InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
    end

    it "completes the task" do
      expect { subject }.to change(IhpDraft, :count).by(0)
      expect(task.reload.status).to eq(Constants.TASK_STATUSES.completed)
    end

    context "when ihp_notification feature toggle is on" do
      let(:path) { "\\\\vacoappbva3.dva.va.gov\\DMDI$\\VBMS Paperless IHPs\\AML\\AMA IHPs\\VetName 12345.pdf" }
      let(:params) { { status: Constants.TASK_STATUSES.completed, ihp_path: path } }

      before { FeatureToggle.enable!(:ihp_notification) }
      after { FeatureToggle.disable!(:ihp_notification) }

      it "completes the task and creates an IHP draft" do
        expect { subject }.to change(IhpDraft, :count).by(1)
        expect(task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(IhpDraft.where(appeal: appeal, organization: organization).count).to eq 1
      end
    end
  end
end
