# frozen_string_literal: true

describe RootTask, :postgres do
  describe ".available_actions_unwrapper" do
    let(:user) { create(:user) }
    let(:root_task) { RootTask.find(create(:root_task).id) }

    subject { root_task.available_actions_unwrapper(user) }

    context "when user is a member of the Mail team" do
      before { allow(user).to receive(:organizations).and_return([MailTeam.singleton]) }

      it "should return a list that includes only the create mail task" do
        expect(subject).to eq([root_task.build_action_hash(Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h, user)])
      end
    end

    context "when user is a member of the Mail team" do
      before { allow(user).to receive(:organizations).and_return([LitigationSupport.singleton]) }

      it "should return a list that includes only the create mail task" do
        expect(subject).to eq([root_task.build_action_hash(Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h, user)])
      end
    end

    context "when user is not a member of the Mail team or Litigation support" do
      it "should return an empty list" do
        expect(subject).to eq([])
      end
    end

    context "when the appeal is a legacy appeal" do
      it "mail team members still have the option to add mail tasks" do
        allow(user).to receive(:organizations).and_return([MailTeam.singleton])

        expect(subject).to eq([root_task.build_action_hash(Constants.TASK_ACTIONS.CREATE_MAIL_TASK.to_h, user)])
      end
    end
  end

  describe ".update_children_status_after_closed" do
    let!(:root_task) { create(:root_task) }
    let!(:appeal) { root_task.appeal }

    subject { root_task.update_children_status_after_closed }

    context "when there are multiple children tasks" do
      let!(:task) { create(:ama_task, parent: root_task) }
      let!(:tracking_task) { create(:track_veteran_task, parent: root_task) }

      it "should only close the tracking task" do
        expect { subject }.to_not raise_error
        expect(tracking_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(task.reload.status).to_not eq(Constants.TASK_STATUSES.completed)
      end
    end
  end

  describe ".when_child_task_completed" do
    let!(:root_task) { create(:root_task) }
    let!(:appeal) { root_task.appeal }

    context "when the Appeal has already been dispatched" do
      let!(:tracking_task) { create(:track_veteran_task, parent: root_task) }
      let!(:dispatch_task) do
        create(:bva_dispatch_task, :completed, closed_at: Time.zone.now - 1, parent: root_task)
      end
      let!(:mail_task) { create(:reconsideration_motion_mail_task, parent: root_task) }

      context "when there are non-closeable child tasks present" do
        let!(:task) { create(:ama_task, parent: root_task) }

        it "the RootTask does not close itself" do
          expect(root_task).to be_on_hold

          mail_task.completed!

          expect(root_task).to be_on_hold
        end
      end

      context "when all the child tasks are close-able" do
        it "the RootTask closes itself" do
          expect(root_task).to be_on_hold

          mail_task.completed!

          expect(root_task.reload).to be_completed
        end
      end
    end
  end

  describe ".set_assignee" do
    context "when retrieving an existing RootTask" do
      let!(:root_task) { create(:root_task, assigned_to: assignee) }
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

          RootTask.create(appeal: create(:appeal), assigned_to: Bva.singleton)
        end
      end

      context "when the assignee is not set" do
        it "should not be called" do
          expect_any_instance_of(RootTask).to receive(:set_assignee).exactly(1).times

          RootTask.create(appeal: create(:appeal))
        end
      end

      context "when a RootTask already exists for the appeal" do
        let(:appeal) { create(:appeal) }

        subject { RootTask.create!(appeal: appeal) }

        before do
          create(:root_task, trait, appeal: appeal)
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

  context "when child tasks are added" do
    let(:root_task) { create(:root_task) }
    let(:task_factory) { :task }

    subject { create(task_factory, parent: root_task) }

    before { allow(Raven).to receive(:capture_message) }

    context "when the RootTask is active" do
      it "changes that status to on_hold" do
        expect(root_task.status).to eq(Constants.TASK_STATUSES.assigned)
        expect(root_task.children.count).to eq(0)

        subject

        expect(root_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(root_task.children.count).to eq(1)
      end
    end

    context "when the RootTask is closed" do
      before { root_task.update!(status: Constants.TASK_STATUSES.completed) }

      it "does not change the status of the RootTask" do
        expect(root_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(root_task.children.count).to eq(0)

        subject

        expect(root_task.status).to eq(Constants.TASK_STATUSES.completed)
        expect(root_task.children.count).to eq(1)
      end

      context "when the child task is a normal 'ol task" do
        it "sends a message to Sentry" do
          subject
          expect(Raven).to have_received(:capture_message).exactly(1).times
        end
      end

      context "when the child task is a TrackVeteranTask" do
        let(:task_factory) { :track_veteran_task }

        it "does not send a message to Sentry" do
          subject
          expect(Raven).to have_received(:capture_message).exactly(0).times
        end
      end

      context "when the child task is a MailTask" do
        let(:task_factory) do
          [
            :appeal_withdrawal_mail_task,
            :appeal_withdrawal_bva_task,
            :returned_undeliverable_correspondence_mail_task,
            :aod_motion_mail_task,
            :reconsideration_motion_mail_task,
            :vacate_motion_mail_task,
            :congressional_interest_mail_task
          ].sample
        end

        # Automatic task assignment requires there to be members of the BVA dispatch team.
        before { BvaDispatch.singleton.add_user(create(:user)) }

        it "does not send a message to Sentry" do
          subject
          expect(Raven).to have_received(:capture_message).exactly(0).times
        end
      end
    end

    context "when the RootTask is on_hold" do
      before { root_task.update!(status: Constants.TASK_STATUSES.on_hold) }

      it "does not change the status of the RootTask" do
        expect(root_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(root_task.children.count).to eq(0)

        subject

        expect(root_task.status).to eq(Constants.TASK_STATUSES.on_hold)
        expect(root_task.children.count).to eq(1)
      end

      context "when the child task is a normal 'ol task" do
        it "does not send a message to Sentry" do
          subject
          expect(Raven).to have_received(:capture_message).exactly(0).times
        end
      end
    end
  end

  context "#assigned_to_label" do
    let!(:root_task) { create(:root_task) }
    let!(:appeal) { root_task.appeal }

    subject { root_task.assigned_to_label }

    context "when the root task is on hold" do
      before { root_task.on_hold! }
      it "returns Unassigned" do
        expect(subject).to eq(COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL)
      end
    end

    context "when the root task is open" do
      before { root_task.in_progress! }
      it "returns Unassigned" do
        expect(subject).to eq(COPY::CASE_LIST_TABLE_UNASSIGNED_LABEL)
      end
    end
  end
end
