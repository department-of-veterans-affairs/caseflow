describe MailTask do
  describe ".create_from_params" do
    let(:user) { FactoryBot.create(:user) }
    let(:appeal) { FactoryBot.create(:appeal) }

    before do
      OrganizationsUser.add_user_to_organization(user, MailTeam.singleton)
    end

    context "when no root_task exists for appeal" do
      let(:params) { { appeal: appeal } }

      it "throws an error" do
        expect { MailTask.create_from_params(params, user) }.to raise_error(Caseflow::Error::NoRootTask)
      end
    end

    context "when root_task exists for appeal" do
      let!(:root_task) { FactoryBot.create(:root_task, appeal: appeal) }
      let(:org) { FactoryBot.create(:organization) }
      let(:params) do
        {
          appeal: appeal,
          assigned_to_id: org.id,
          assigned_to_type: org.class.name,
          parent_id: root_task.id
        }
      end

      it "creates MailTask and GenericTask" do
        expect { MailTask.create_from_params(params, user) }.to_not raise_error
        expect(root_task.children.length).to eq(1)

        mail_task = root_task.children[0]
        expect(mail_task.class).to eq(MailTask)
        expect(mail_task.assigned_to).to eq(MailTeam.singleton)
        expect(mail_task.children.length).to eq(1)

        generic_task = mail_task.children[0]
        expect(generic_task.class).to eq(GenericTask)
        expect(generic_task.assigned_to.class).to eq(org.class)
        expect(generic_task.assigned_to.id).to eq(org.id)
        expect(generic_task.children.length).to eq(0)
      end
    end
  end
end
