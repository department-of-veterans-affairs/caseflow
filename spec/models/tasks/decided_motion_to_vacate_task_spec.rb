# frozen_string_literal: true

RSpec.describe DecidedMotionToVacateTask, :postgres, type: :model do
  let(:lit_support_team) { LitigationSupport.singleton }

  describe ".automatically_create_org_task" do
    subject { create(:denied_motion_to_vacate_task) }

    it "should automatically create org task" do
      subject
      org_task = DeniedMotionToVacateTask.find_by(assigned_to: lit_support_team)
      expect(org_task).to_not be nil
    end
  end

  describe ".available_actions_unwrapper" do
    let(:attorney) { create(:user) }

    subject { task.available_actions_unwrapper(attorney) }

    context "the task is assigned to a user" do
      context "the task is assigned to the attorney" do
        let!(:task) { create(:denied_motion_to_vacate_task, assigned_to: attorney) }

        it "has available actions" do
          expect(subject.length).to be > 0
        end

        it "should include Pulac Cerullo action in available actions" do
          expect(subject).to include(hash_including(Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h))
        end
      end

      context "the task is assigned to someone else" do
        let(:another_attorney) { create(:user) }
        let!(:task) { create(:denied_motion_to_vacate_task, assigned_to: another_attorney) }

        it "doesn't have any available actions" do
          expect(subject).to be_empty
        end
      end
    end

    context "the task is assigned to an organization" do
      let(:organization) { create(:organization) }
      let!(:task) { create(:dismissed_motion_to_vacate_task, assigned_to: organization) }

      context "the attorney is an admin in the organization" do
        before { OrganizationsUser.make_user_admin(attorney, organization) }

        it "has available actions" do
          expect(subject.length).to be > 0
        end
      end

      context "the attorney is not an admin in the organization" do
        before { organization.add_user(attorney) }

        it "doesn't have any available actions" do
          expect(subject).to be_empty
        end
      end
    end
  end
end
