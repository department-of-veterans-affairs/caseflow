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
        let(:dist_task) { appeal.tasks.active.of_type(:DistributionTask).first }

        context "with no blocking tasks" do
          it_behaves_like "successful creation"
        end

        it_behaves_like "appeal has a nonblocking mail task"

        context "with blocking mail task" do
          before do
            create(:extension_request_mail_task,
                   appeal: appeal,
                   parent: dist_task)
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
        let(:dist_task) { appeal.tasks.open.of_type(:DistributionTask).first }

        context "with distribution task on_hold" do
          it "should error with appeal not ready" do
            expect { subject }.to raise_error do |error|
              expect(error).to be_a(Caseflow::Error::IneligibleForSpecialCaseMovement)
              expect(error.appeal_id).to eq(appeal.id)
            end
          end
        end

        it_behaves_like "wrong parent task type provided"
      end

      it_behaves_like "appeal past distribution" do
        let(:expected_error) { Caseflow::Error::IneligibleForSpecialCaseMovement }
      end
    end

    it_behaves_like "non Case Movement user provided"
  end
end
