# frozen_string_literal: true

require_relative "special_case_movement_shared_examples"

describe SpecialCaseMovementTask do
  describe ".create" do
    context "with Case Movement Team user" do
      let(:cm_user) { create(:user) }

      subject do
        SpecialCaseMovementTask.create!(appeal: appeal,
                                        assigned_to: cm_user,
                                        assigned_by: cm_user,
                                        parent: dist_task)
      end

      before do
        SpecialCaseMovementTeam.singleton.add_user(cm_user)
      end

      context "appeal ready for distribution" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end
        let(:dist_task) { appeal.tasks.active.where(type: DistributionTask.name).first }

        context "with no blocking tasks" do
          it_behaves_like "completed distribution and at JudgeAssign"
        end

        it_behaves_like "succeeds when there's a nonblocking mail task"

        context "with blocking mail task" do
          before do
            create(:extension_request_mail_task,
                   appeal: appeal,
                   parent: appeal.root_task)
          end
          it "should error with appeal not ready" do
            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Caseflow::Error::IneligibleForSpecialCaseMovement)
            end
          end
        end
      end

      context "appeal at the evidence window state" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.evidence_submission)
        end
        let(:dist_task) { appeal.tasks.open.where(type: DistributionTask.name).first }

        context "with distribution task on_hold" do
          it "should error with appeal not ready" do
            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Caseflow::Error::IneligibleForSpecialCaseMovement)
              expect(error.appeal_id).to eq(appeal.id)
            end
          end
        end

        it_behaves_like "wrong parent task type"
      end

      it_behaves_like "appeal past distribution fails" do
        let(:expected_error) { Caseflow::Error::IneligibleForSpecialCaseMovement }
      end
    end

    it_behaves_like "fails with wrong user"
  end
end
