# frozen_string_literal: true

require "rails_helper"

describe SpecialCaseMovementTask do
  describe ".create" do
    context "with Special Case Movement Team user" do
      before do
        let (:scm_user) { FactoryBot.create(:user) }
        OrganizationsUser.add_user_to_organization(scm_user,
                                                   SpecialCaseMovementTeam.singleton)
      end

      context "appeal ready for distribution" do
        before do
          let (:appeal) { FactoryBot.create(:appeal,
                                            :with_post_intake_tasks,
                                            docket_type: "direct_review")}
        end
        context "with no blocking tasks" do
          it "should create the SCM task and JudgeAssign task" do
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: appeal.root_task)
            end.not_to raise_error
            scm_task = tasks.open.where(type: SpecialCaseManagementTask.name).first
            expect(scm_task.status).to eq(TASK_STATUSES.completed)

            judge_task = tasks.open.where(type: JudgeAssignTask.name).first
            expect(judge_task.status).to eq(TASK_STATUSES.assigned)
          end
        end

        context "with blocking mail task" do
          before do
            FactoryBot.create(:congressional_interest_mail_task,
                              appeal: appeal,
                              parent: appeal.root_task)
          end
          it "should error with appeal not ready" do
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: appeal.root_task)
            end.to raise_error(InvalidAppealState)
          end
        end
      end

      context "appeal at the evidence window state" do
        before do
          let (:appeal) { FactoryBot.create(:appeal,
                                            :with_post_intake_tasks,
                                            docket_type: "evidence_submission")}
        end
        context "with distribution task on_hold" do
          it "should error with appeal not ready" do
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: appeal.root_task)
            end.to raise_error(InvalidAppealState)
          end
        end

        context "with the evidence window task as parent" do
          it "should error with wrong parent type" do
            evidence_window_task = tasks.open.where(type: EvidenceSubmissionWindowTask.name).first
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: evidence_window_task)
            end.to raise_error(InvalidParentTask)
          end
        end
      end
    end

    context "with regular user" do
      before do
        let (:user) { FactoryBot.create(:user) }
        let (:appeal) { FactoryBot.create(:appeal,
                                          :with_post_intake_tasks,
                                          docket_type: "direct_review")}
      end

      it "should error with user error" do
        expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: user,
                                             parent: appeal.root_task)
        end.to raise_error(ActionForbiddenError)
      end
    end
  end
end
