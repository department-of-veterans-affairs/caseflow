# frozen_string_literal: true

describe LegacyAppealAssignmentTrackingTask do
  describe ".create" do
    context "with Special Case Movement Team user" do
      let(:scm_user) { create(:user) }
      let(:cancelled_tasks) { "Tasks that were cancelled" }
      let(:cancellation_instructions) { "Cancelling task" }
      let(:assign_instructions) { "Assigning task" }
      let(:instructions) { [cancellation_instructions, assign_instructions] }

      subject do
        LegacyAppealAssignmentTrackingTask.create!(appeal: appeal,
                                                   assigned_to: scm_user,
                                                   assigned_by_id: scm_user.id,
                                                   instructions: instructions,
                                                   status: Constants.TASK_STATUSES.completed)
      end

      before do
        SpecialCaseMovementTeam.singleton.add_user(scm_user)
      end

      shared_examples "cancelled blocking children" do
        it "cancel any open blocking hearing tasks and descendants" do
          hear_task = appeal.tasks.open.of_type(:HearingTask).first
          open_tasks = hear_task.descendants.select(&:open?)
          expect { subject }.not_to raise_error
          open_tasks.each do |task|
            expect(task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
            expect(task.reload.instructions).to eq([cancellation_instructions])
          end
        end
      end

      shared_examples "successful legacy creation" do
        it "creates the LegacyAppealAssignmentTrackingTask" do
          expect { subject }.not_to raise_error
          laatt_task =  appeal.tasks.of_type(described_class.name).first
          expect(laatt_task.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      shared_examples "InvalidAppealTypeOnTaskCreate" do
        context "appeal is not a legacy appeal" do
          it "should error with invalid appeal type" do
            expect { subject }.to raise_error(Caseflow::Error::InvalidAppealTypeOnTaskCreate)
          end
        end
      end

      shared_examples "InvalidStatusOnTaskCreate" do
        context "status is not complete" do
          it "should error with invalid status" do
            expect { subject }.to raise_error(Caseflow::Error::InvalidStatusOnTaskCreate)
          end
        end
      end

      context "legacy appeal blocked for distribution" do
        let(:appeal) do
          create(:legacy_appeal,
                 :with_schedule_hearing_tasks,
                 vacols_case: create(
                   :case_with_form_9,
                   :type_original,
                   :status_active,
                   case_issues: create_list(:case_issue, 2, :compensation)
                 ))
        end
        let(:hear_task) { appeal.tasks.active.of_type(:HearingTask).first }
        let(:instructions) { [cancelled_tasks, cancellation_instructions, assign_instructions] }

        before do
          FeatureToggle.enable!(:legacy_case_movement_scm_to_vlj_for_blockhtask)
        end

        after do
          FeatureToggle.disable!(:legacy_case_movement_scm_to_vlj_for_blockhtask)
        end

        context "with blocking tasks" do
          it_behaves_like "successful legacy creation"
          it_behaves_like "cancelled blocking children"
        end
      end

      context "legacy appeal ready for distribution" do
        let(:appeal) do
          create(:legacy_appeal,
                 vacols_case: create(
                   :case_with_form_9,
                   :type_original,
                   :status_active,
                   case_issues: create_list(:case_issue, 2, :compensation)
                 ))
        end
        let(:instructions) { [assign_instructions] }

        context "with no blocking tasks" do
          it_behaves_like "successful legacy creation"
        end
      end

      context "AMA appeal ready for distribution" do
        let(:appeal) do
          create(:appeal,
                 :with_post_intake_tasks,
                 docket_type: Constants.AMA_DOCKETS.direct_review)
        end
        let(:instructions) { [assign_instructions] }

        context "with no blocking tasks" do
          it_behaves_like "InvalidAppealTypeOnTaskCreate"
        end

        context "with LegacyAppealAssignmentTrackingTask status as assigned" do
          subject do
            LegacyAppealAssignmentTrackingTask.create!(appeal: appeal,
                                                       assigned_to: scm_user,
                                                       assigned_by_id: scm_user.id,
                                                       instructions: instructions,
                                                       status: Constants.TASK_STATUSES.assigned)
          end

          it_behaves_like "InvalidStatusOnTaskCreate"
        end
      end
    end
  end
end
