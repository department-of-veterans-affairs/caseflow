# frozen_string_literal: true

describe AttorneyQueue, :all_dbs do
  context "#tasks" do
    let(:user) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    subject { AttorneyQueue.new(user: user).tasks }

    context "when colocated admin actions are on hold" do
      let!(:vlj_support_staff) do
        Colocated.singleton.add_user(create(:user))
        Colocated.singleton.users.first
      end

      let(:org1) { Colocated.singleton }
      let!(:action1) { create(:colocated_task, assigned_by: user, assigned_to: org1) }
      let(:org2) { Colocated.singleton }
      let!(:action2) { create(:colocated_task, :ihp, appeal: appeal, assigned_by: user, assigned_to: org2) }
      let!(:action3) do
        create(
          :colocated_task,
          :poa_clarification,
          appeal: appeal,
          assigned_by: user
        ).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end
      let!(:action4) do
        create(:colocated_task, assigned_by: user).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end
      let(:org5) { Colocated.singleton }
      let!(:action5) do
        create(:colocated_task, :in_progress, assigned_by: user, assigned_to: org5)
      end

      it "should return the list" do
        expect(subject.size).to eq 3
        expect(subject[0].status).to eq "on_hold"
        expect(subject[1].status).to eq "on_hold"
        expect(subject[2].status).to eq "on_hold"
      end

      context "admin actions are assigned to organizations other than Colocated" do
        let(:org1) { PrivacyTeam.singleton }
        let(:org2) { Translation.singleton }
        let(:org5) { HearingsManagement.singleton }

        it "returns the list" do
          expect(subject.size).to eq 3
          expect(subject[0].status).to eq "on_hold"
          expect(subject[1].status).to eq "on_hold"
          expect(subject[2].status).to eq "on_hold"
        end
      end
    end

    context "when complete and incomplete colocated admin actions exist for an appeal" do
      let!(:vlj_support_staff) do
        Colocated.singleton.add_user(create(:user))
        Colocated.singleton.users.first
      end

      let!(:completed_action) do
        create(
          :colocated_task,
          appeal: appeal,
          assigned_by: user
        ).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.completed)
        end
      end
      let!(:incomplete_action) do
        create(
          :colocated_task,
          appeal: appeal,
          assigned_by: user
        ).tap do |task|
          task.children.first.update!(status: Constants.TASK_STATUSES.on_hold)
        end
      end

      it "should only return the incomplete colocated admin actions" do
        expect(subject.size).to eq(1)
        expect(subject.first).to eq(incomplete_action)
      end
    end
  end
end
