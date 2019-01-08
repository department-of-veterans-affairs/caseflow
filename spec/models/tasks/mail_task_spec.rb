describe MailTask do
  describe ".create_from_params" do
    let(:user) { FactoryBot.create(:user) }
    let(:appeal) { FactoryBot.create(:appeal) }
    let(:mail_team) { MailTeam.singleton }

    # Use AodMotionMailTask because we do create subclasses of MailTask, never MailTask itself.
    let(:task_class) { AodMotionMailTask }
    let(:params) { { appeal: appeal, parent_id: root_task_id, type: task_class.name } }

    before do
      OrganizationsUser.add_user_to_organization(user, mail_team)
    end

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
  end
end
