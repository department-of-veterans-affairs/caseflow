# frozen_string_literal: true

require "rails_helper"

describe SpecialCaseMovementTask do
  describe ".create" do
    context "with Special Case Movement Team user" do
      let(:scm_user) { FactoryBot.create(:user) }
      before do
        OrganizationsUser.add_user_to_organization(scm_user,
                                                   SpecialCaseMovementTeam.singleton)
      end

      context "appeal ready for distribution" do
        let(:appeal) do
          FactoryBot.create(:appeal,
                            :with_post_intake_tasks,
                            docket_type: "direct_review")
        end
        context "with no blocking tasks", focus: true do
          it "should create the SCM task and JudgeAssign task" do
            expect do
              dist_task = appeal.tasks.active.where(type: DistributionTask.name).first
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_to: scm_user,
                                             parent: dist_task)
            end.not_to raise_error
            scm_task = appeal.tasks.open.where(type: SpecialCaseMovementTask.name).first
            expect(scm_task.status).to eq(TASK_STATUSES.completed)

            judge_task = appeal.tasks.open.where(type: JudgeAssignTask.name).first
            expect(judge_task.status).to eq(TASK_STATUSES.assigned)
          end
        end

        context "with blocking mail task" do
          it "should error with appeal not ready" do
            FactoryBot.create(:congressional_interest_mail_task,
                              appeal: appeal,
                              parent: appeal.root_task)
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: appeal.root_task)
            end.to raise_error(Caseflow::Error::InvalidAppealState, appeal_id: appeal.id, action: "SpecialCaseMovement")
          end
        end

        context "with a nonblocking mail task" do
          it "shouldn't error with appeal not ready" do
            FactoryBot.create(:aod_motion_mail_task,
                              appeal: appeal,
                              parent: appeal.root_task)
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: appeal.root_task)
            end.not_to raise_error
          end
        end
      end

      context "appeal at the evidence window state" do
        let(:appeal) do
          FactoryBot.create(:appeal,
                            :with_post_intake_tasks,
                            docket_type: "evidence_submission")
        end
        context "with distribution task on_hold" do
          it "should error with appeal not ready" do
            expect do
              dist_task = appeal.tasks.open.where(type: DistributionTask.name).first
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: dist_task)
            end.to raise_error(Caseflow::Error::InvalidAppealState, appeal_id: appeal.id, action: "SpecialCaseMovement")
          end
        end

        context "with the evidence window task as parent" do
          it "should error with wrong parent type" do
            evidence_window_task = tasks.open.where(type: EvidenceSubmissionWindowTask.name).first
            expect do
              SpecialCaseMovementTask.create(appeal: appeal,
                                             assigned_by: scm_user,
                                             parent: evidence_window_task)
            end.to raise_error(Caseflow::Error::InvalidParentTask, task_type: EvidenceSubmissionWindowTask.name)
          end
        end
      end
    end

    context "with regular user" do
      let(:user) { FactoryBot.create(:user) }
      let(:appeal) do
        FactoryBot.create(:appeal,
                          :with_post_intake_tasks,
                          docket_type: "direct_review")
      end

      it "should error with user error" do
        expect do
          SpecialCaseMovementTask.create(appeal: appeal,
                                         assigned_by: user,
                                         parent: appeal.root_task)
        end.to raise_error(Caseflow::Error::ActionForbiddenError)
      end
    end
  end
end
