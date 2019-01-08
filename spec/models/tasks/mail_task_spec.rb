describe MailTask do
  let(:user) { FactoryBot.create(:user) }
  let(:mail_team) { MailTeam.singleton }
  before do
    OrganizationsUser.add_user_to_organization(user, mail_team)
  end

  describe ".create_from_params" do
    let(:appeal) { FactoryBot.create(:appeal) }

    # Use AodMotionMailTask because we do create subclasses of MailTask, never MailTask itself.
    let(:task_class) { AodMotionMailTask }
    let(:params) { { appeal: appeal, parent_id: root_task_id, type: task_class.name } }

    context "when no root_task exists for appeal" do
      let(:root_task_id) { nil }

      it "throws an error" do
        expect { task_class.create_from_params(params, user) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when root_task exists for appeal" do
      let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:root_task_id) { root_task.id }

      it "creates AodMotionMailTask assigned to MailTeam and AodTeam" do
        expect { task_class.create_from_params(params, user) }.to_not raise_error
        expect(root_task.children.length).to eq(1)

        mail_task = root_task.children[0]
        expect(mail_task.class).to eq(task_class)
        expect(mail_task.assigned_to).to eq(mail_team)
        expect(mail_task.children.length).to eq(1)

        child_task = mail_task.children[0]
        expect(child_task.class).to eq(task_class)
        expect(child_task.assigned_to).to eq(AodTeam.singleton)
        expect(child_task.children.length).to eq(0)
      end
    end

    context "when child task creation fails" do
      let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:root_task_id) { root_task.id }

      before do
        allow(task_class).to receive(:create_child_task).and_raise(StandardError)
      end

      it "should not create any mail tasks" do
        expect { task_class.create_from_params(params, user) }.to raise_error(StandardError)
        expect(root_task.children.length).to eq(0)
      end
    end

    context "when user is not a member of the mail team" do
      let(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:root_task_id) { root_task.id }

      let(:non_mail_user) { FactoryBot.create(:user) }

      it "should raise an error" do
        expect { task_class.create_from_params(params, non_mail_user) }.to raise_error(
          Caseflow::Error::ActionForbiddenError
        )
      end
    end
  end

  # TODO: Add tests for:
  # outstanding_cavc_tasks?
  # pending_hearing_task?
  # case_active?
  # most_recent_active_task_assignee

  describe ".child_task_assignee (routing logic)" do
    let(:root_task) { FactoryBot.create(:root_task) }
    let(:mail_task) { task_class.create!(appeal: root_task.appeal, parent_id: root_task.id, assigned_to: mail_team) }
    let(:params) { {} }

    subject { task_class.child_task_assignee(mail_task, params) }

    context "for an AddressChangeMailTask" do
      let(:task_class) { AddressChangeMailTask }

      context "when the appeal has a pending hearing task" do
        before { allow(task_class).to receive(:pending_hearing_task?).and_return(true) }

        it "should route to hearings management branch" do
          expect(subject).to eq(HearingsManagement.singleton)
        end
      end

      context "when the appeal is not active" do
        before { allow(task_class).to receive(:case_active?).and_return(false) }

        it "should raise an error" do
          expect { subject }.to raise_error(Caseflow::Error::MailRoutingError)
        end
      end

      context "when the appeal is active and has no pending_hearing_task" do
        it "should route to VLJ support staff" do
          expect(subject).to eq(Colocated.singleton)
        end
      end
    end

    context "for an AodMotionMailTask" do
      let(:task_class) { AodMotionMailTask }

      it "should always route to the AOD team" do
        expect(subject).to eq(AodTeam.singleton)
      end
    end
  end
end
