# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe AttorneyQueue, :all_dbs do
  context "#tasks" do
    let(:user) { create(:user) }
    let!(:staff) { create(:staff, :attorney_role, sdomainid: user.css_id) }
    let(:appeal) { create(:legacy_appeal, vacols_case: create(:case)) }

    subject { AttorneyQueue.new(user: user).tasks }

    context "when colocated admin actions are on hold" do
      let!(:vlj_support_staff) do
        OrganizationsUser.add_user_to_organization(create(:user), Colocated.singleton)
        Colocated.singleton.users.first
      end

      let!(:action1) { create(:colocated_task, assigned_by: user) }
      let!(:action2) { create(:colocated_task, appeal: appeal, assigned_by: user) }
      let!(:action3) do
        create(
          :colocated_task,
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
      let!(:action5) do
        create(:colocated_task, :in_progress, assigned_by: user)
      end

      it "should return the list" do
        expect(subject.size).to eq 3
        expect(subject[0].status).to eq "on_hold"
        expect(subject[1].status).to eq "on_hold"
        expect(subject[2].status).to eq "on_hold"
      end
    end

    context "when complete and incomplete colocated admin actions exist for an appeal" do
      let!(:vlj_support_staff) do
        OrganizationsUser.add_user_to_organization(create(:user), Colocated.singleton)
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
