# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe RootTask, :postgres do
  describe ".available_actions_unwrapper" do
    let(:user) { FactoryBot.create(:user) }
    let(:root_task) { RootTask.find(FactoryBot.create(:root_task).id) }

    subject { root_task.available_actions_unwrapper(user) }

    context "when user is a member of the Mail team" do
      before { allow_any_instance_of(MailTeam).to receive(:user_has_access?).and_return(true) }

      it "should return a list that includes only the create mail task" do
        expect(subject).to eq([root_task.build_action_hash(Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h, user)])
      end
    end

    context "when user is not a member of the Mail team" do
      it "should return an empty list" do
        expect(subject).to eq([])
      end
    end
  end

  describe ".update_children_status_after_closed" do
    let!(:root_task) { FactoryBot.create(:root_task) }
    let!(:appeal) { root_task.appeal }

    subject { root_task.update_children_status_after_closed }

    context "when there are multiple children tasks" do
      let!(:generic_task) { FactoryBot.create(:generic_task, appeal: appeal, parent: root_task) }
      let!(:tracking_task) { FactoryBot.create(:track_veteran_task, appeal: appeal, parent: root_task) }

      it "should close the tracking task but not the generic task" do
        expect { subject }.to_not raise_error
        expect(tracking_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(generic_task.reload.status).to_not eq(Constants.TASK_STATUSES.completed)
      end
    end
  end

  describe ".set_assignee" do
    context "when retrieving an existing RootTask" do
      let!(:root_task) { FactoryBot.create(:root_task, assigned_to: assignee) }
      context "when the assignee is already set" do
        let(:assignee) { Bva.singleton }

        it "should not be called" do
          expect_any_instance_of(RootTask).to_not receive(:set_assignee)

          RootTask.find(root_task.id)
        end
      end
    end

    context "when creating a new RootTask" do
      context "when the assignee is already set" do
        it "should not be called" do
          expect_any_instance_of(RootTask).to_not receive(:set_assignee)

          RootTask.create(appeal: FactoryBot.create(:appeal), assigned_to: Bva.singleton)
        end
      end

      context "when the assignee is not set" do
        it "should not be called" do
          expect_any_instance_of(RootTask).to receive(:set_assignee).exactly(1).times

          RootTask.create(appeal: FactoryBot.create(:appeal))
        end
      end

      context "when a RootTask already exists for the appeal" do
        let(:appeal) { FactoryBot.create(:appeal) }

        subject { RootTask.create!(appeal: appeal) }

        before do
          FactoryBot.create(:root_task, trait, appeal: appeal)
        end

        context "when existing RootTask is active" do
          let(:trait) { :on_hold }
          it "will raise an error" do
            expect { subject }.to raise_error(Caseflow::Error::DuplicateOrgTask)
          end
        end

        context "when existing RootTask is inactive" do
          let(:trait) { :completed }
          it "will raise an error" do
            expect { subject }.to raise_error(Caseflow::Error::DuplicateOrgTask)
          end
        end
      end
    end
  end
end
