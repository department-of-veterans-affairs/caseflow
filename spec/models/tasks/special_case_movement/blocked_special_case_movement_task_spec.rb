# frozen_string_literal: true

require_relative "../special_case_movement_shared_examples"

describe BlockedSpecialCaseMovementTask do
  describe ".create" do
    context "with Case Movement Team user" do
      let(:cm_user) { create(:user) }

      subject do
        BlockedSpecialCaseMovementTask.create!(appeal: appeal,
                                               assigned_to: cm_user,
                                               assigned_by: cm_user,
                                               parent: dist_task)
      end

      before do
        SpecialCaseMovementTeam.singleton.add_user(cm_user)
      end

      shared_examples "cancelled distribution children" do
        it "cancel any open distribution descendants" do
          dist_task = appeal.tasks.open.where(type: DistributionTask.name).first
          open_tasks = dist_task.descendants.select(&:open?) - [dist_task]
          expect { subject }.not_to raise_error
          open_tasks.each do |task|
            expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
          end
        end
      end

      context "appeal ready for distribution" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end
        let(:dist_task) { appeal.tasks.active.where(type: DistributionTask.name).first }

        context "with no distribution blocking tasks" do
          it_behaves_like "successful creation"
        end

        it_behaves_like "appeal has a non distribution-blocking mail task"

        context "with a distribution blocking mail task" do
          before do
            create(:extension_request_mail_task,
                   appeal: appeal,
                   parent: dist_task)
          end
          it_behaves_like "successful creation"
          it_behaves_like "cancelled distribution children"
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
          it_behaves_like "successful creation"
          it_behaves_like "cancelled distribution children"
        end

        it_behaves_like "wrong parent task type provided"
      end

      it_behaves_like "appeal past distribution" do
        let(:expected_error) { Caseflow::Error::IneligibleForBlockedSpecialCaseMovement }
      end
    end

    it_behaves_like "non Case Movement user provided"
  end
end
