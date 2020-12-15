# frozen_string_literal: true

describe CavcCorrespondenceMailTask do
  let(:mail_user) { create(:user) }
  let(:cavc_lit_user) { create(:user) }
  let(:cavc_task) { create(:cavc_task) }

  before do
    MailTeam.singleton.add_user(mail_user)
    CavcLitigationSupport.singleton.add_user(cavc_lit_user)
  end

  # TK: Org and User tasks
  describe ".available_actions" do
    let(:appeal) { create(:appeal, :type_cavc_remand, :with_post_intake_tasks) }
    let(:mail_task) { described_class.create_from_params({appeal: appeal, parent_id: appeal.root_task.id}, mail_user) }

    subject do
      expect(mail_task.available_actions(user)).to eq(expected_actions)
      expect(mail_task.parent.available_actions(user)).to eq(expected_actions)
    end

    context "mail team user" do
      let(:user) { mail_user }
      let(:expected_actions) { [] }

      it "has no actions" do
        subject
      end
    end

    context "CAVC Litigation Support team member" do
      context "CAVC Litigation Support team admin" do
        let(:user) { cavc_lit_user }
        let(:expected_actions) { [] }

        before do
          OrganizationsUser.make_user_admin(user, CavcLitigationSupport.singleton)
        end

        it "has actions"
      end

      context "CAVC Litigation Support team admin" do
        it "has no actions"
      end
    end
  end

  describe ".create_from_params" do
    let(:params) { { parent_id: root_task.id, instructions: "foo bar" } }

    subject { CavcCorrespondenceMailTask.create_from_params(params, mail_user) }

    before { RequestStore[:current_user] = mail_user }

    context "on a non-CAVC Appeal Stream" do
      let(:root_task) { create(:root_task) }

      it "fails to create the task" do
        expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end

    context "on a CAVC Appeal Stream" do
      let(:appeal) { create(:appeal, :type_cavc_remand, :with_post_intake_tasks) }

      context "without a CAVC task" do
        let(:appeal) { create(:appeal, :type_cavc_remand) }
        let(:root_task) { RootTask.create!(appeal: appeal)  }

        it "fails to create the task" do
          expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "after the CAVC Lit Support work is complete" do
        let(:root_task) { appeal.root_task }

        before { CavcTask.find_by(appeal: appeal).completed! }

        it "fails to create the task" do
          expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "while still with CAVC Lit Support" do
        let(:root_task) { appeal.root_task }

        it "creates an org task each for Mail team and CAVC Lit Support" do
          expect(CavcCorrespondenceMailTask.all.size).to eq(0)
          subject
          expect(CavcCorrespondenceMailTask.where(assigned_to_type: "Organization").size).to eq(2)
          expect(CavcCorrespondenceMailTask.first.assigned_to).to eq(MailTeam.singleton)
          expect(CavcCorrespondenceMailTask.second.assigned_to).to eq(CavcLitigationSupport.singleton)
        end
      end
    end
  end
end
