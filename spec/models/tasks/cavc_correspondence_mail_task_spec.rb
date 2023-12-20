# frozen_string_literal: true

describe CavcCorrespondenceMailTask do
  let(:mail_user) { create(:user) }
  let(:cavc_lit_user) { create(:user) }
  let(:cavc_task) { create(:cavc_task) }

  before do
    MailTeam.singleton.add_user(mail_user)
    CavcLitigationSupport.singleton.add_user(cavc_lit_user)
  end

  describe ".available_actions" do
    let(:appeal) { create(:appeal, :type_cavc_remand) }
    let(:mail_task) do
      described_class.create_from_params({ appeal: appeal, parent_id: appeal.root_task.id }, mail_user)
    end

    # organization-level-tasks
    let(:mail_task_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    let(:mail_task_user_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    context "when assigned to an Organization" do
      subject do
        expect(mail_task.available_actions(user)).to eq(expected_actions)
        expect(mail_task.parent.available_actions(user)).to eq(expected_actions)
      end

      context "a mail team user" do
        let(:user) { mail_user }
        let(:expected_actions) { [] }

        it "has no actions" do
          subject
        end
      end

      context "a CAVC Litigation Support team user" do
        let(:user) { cavc_lit_user }

        context "who is a team admin" do
          let(:expected_actions) { mail_task_actions }

          before { OrganizationsUser.make_user_admin(user, CavcLitigationSupport.singleton) }

          it "has actions" do
            subject
          end
        end

        context "who is a team member" do
          let(:expected_actions) { mail_task_actions }

          it "has actions" do
            subject
          end
        end
      end
    end

    context "when assigned to a User" do
      let(:mail_user_task) do
        described_class.create_from_params({ appeal: appeal,
                                             parent_id: mail_task.id,
                                             assigned_to: cavc_lit_user2 },
                                           cavc_lit_user)
      end

      let(:cavc_lit_user2) { create(:user) }

      before do
        CavcLitigationSupport.singleton.add_user(cavc_lit_user2)
        OrganizationsUser.make_user_admin(cavc_lit_user, CavcLitigationSupport.singleton)
      end

      subject { expect(mail_user_task.available_actions(user)).to eq(expected_actions) }

      context "a mail team user" do
        let(:user) { mail_user }
        let(:expected_actions) { [] }

        it "has no actions" do
          subject
        end
      end

      context "a CAVC Litigation Support team member" do
        let(:user) { cavc_lit_user }

        context "who is a team admin" do
          let(:expected_actions) { mail_task_user_actions }

          it "has actions" do
            subject
          end
        end

        context "who is not an admin" do
          context "and is assigned the task" do
            let(:user) { cavc_lit_user2 }
            let(:expected_actions) { mail_task_user_actions }

            it "has actions" do
              subject
            end
          end

          context "and is not assigned the task" do
            let(:expected_actions) { mail_task_user_actions }
            let(:user) { create(:user) }

            before { CavcLitigationSupport.singleton.add_user(user) }

            it "has actions" do
              subject
            end
          end
        end
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
      let(:appeal) { create(:appeal, :type_cavc_remand) }
      let(:root_task) { appeal.root_task }

      context "without a CAVC task" do
        before { CavcTask.find_by(appeal: appeal).destroy }

        it "fails to create the task" do
          expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "after the CAVC Lit Support work is complete" do
        before { CavcTask.find_by(appeal: appeal).completed! }

        it "fails to create the task" do
          expect { subject }.to raise_error(Caseflow::Error::ActionForbiddenError)
        end
      end

      context "while still with CAVC Lit Support" do
        it "creates an org task each for Mail team and CAVC Lit Support" do
          expect(CavcCorrespondenceMailTask.all.size).to eq(0)
          subject
          expect(CavcCorrespondenceMailTask.assigned_to_any_org.size).to eq(2)
          expect(CavcCorrespondenceMailTask.first.assigned_to).to eq(MailTeam.singleton)
          expect(CavcCorrespondenceMailTask.second.assigned_to).to eq(CavcLitigationSupport.singleton)
        end
      end
    end
  end
end
