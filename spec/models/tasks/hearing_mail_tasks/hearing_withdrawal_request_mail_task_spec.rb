# frozen_string_literal: true

describe HearingWithdrawalRequestMailTask, :postgres do
  let(:user) { create(:user) }

  context "The hearing is associated with an AMA appeal" do
    describe "#available_actions" do
      let(:task_actions) do
        [
          Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
          Constants.TASK_ACTIONS.COMPLETE_AND_WITHDRAW.to_h,
          Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
          Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end
      let(:reduced_task_actions) do
        [
          Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
          Constants.TASK_ACTIONS.CANCEL_TASK.to_h
        ]
      end

      context "when user does not belong to the hearing admin team" do
        it "returns an empty array" do
          expect(subject.available_actions(user).length).to eq(0)
        end
      end

      context "when user belongs to the hearing admin team" do
        before { HearingAdmin.singleton.add_user(user) }

        shared_examples "returns appropriate task actions" do
          it "returns appropriate task actions" do
            expect(hwr.available_actions(user).length).to eq(5)
            expect(hwr.available_actions(user)).to eq(task_actions)
          end
        end

        shared_examples "returns appropriate reduced task actions" do
          it "returns appropriate reduced task actions" do
            expect(hwr.available_actions(user).length).to eq(2)
            expect(hwr.available_actions(user)).to eq(reduced_task_actions)
          end
        end

        context "when there is an active ScheduleHearingTask in the appeal's task tree" do
          let(:hwr) { create(:hearing_withdrawal_request_mail_task, :withdrawal_request_with_unscheduled_hearing) }

          include_examples "returns appropriate task actions"
        end

        context "when there is an open AssignHearingDispositionTask in the appeal's task tree" do
          let(:hwr) { create(:hearing_withdrawal_request_mail_task, :withdrawal_request_with_scheduled_hearing) }

          context "when the hearing is scheduled in the past" do
            before do
              allow_any_instance_of(Hearing).to receive(:scheduled_for).and_return(Time.zone.yesterday)
            end

            include_examples "returns appropriate reduced task actions"
          end

          context "when the hearing is not scheduled in the past" do
            before do
              allow_any_instance_of(Hearing).to receive(:scheduled_for).and_return(Time.zone.tomorrow)
            end

            include_examples "returns appropriate task actions"

            context "when there is a child ChangeHearingDispositionTask in the appeal's task tree" do
              let(:appeal) { hwr.appeal }
              let(:disposition_task) { appeal.tasks.find_by(type: AssignHearingDispositionTask.name) }
              let(:hearing_task) { appeal.tasks.find_by(type: HearingTask.name) }

              before do
                disposition_task.update!(status: "completed", closed_at: Time.zone.now)
                ChangeHearingDispositionTask.create!(appeal: appeal, parent: hearing_task,
                                                     assigned_to: HearingAdmin.singleton)
              end

              include_examples "returns appropriate task actions"
            end
          end
        end

        context "when there is neither an active ScheduleHearingTask " \
                "nor an open AssignHearingDispositionTask in the appeal's task tree" do
          let(:hwr) { create(:hearing_withdrawal_request_mail_task, :withdrawal_request_with_unscheduled_hearing) }
          let(:schedule_hearing_task) { hwr.appeal.tasks.find_by(type: ScheduleHearingTask.name) }

          before do
            schedule_hearing_task.cancel_task_and_child_subtasks
          end

          include_examples "returns appropriate reduced task actions"
        end
      end
    end
  end

  describe "hearing withdrawn through completion of alternate task" do
    let(:appeal) { hwr.appeal }
    let(:hwr) { create(:hearing_withdrawal_request_mail_task, :withdrawal_request_with_scheduled_hearing) }
    let(:child_hwr) { hwr.children.first }
    let(:formatted_date) { hwr.updated_at.strftime("%m/%d/%Y") }
    let(:disposition_task) { appeal.tasks.of_type(AssignHearingDispositionTask.name).first }

    before do
      HearingAdmin.singleton.add_user(user)
      RequestStore[:current_user] = user
    end

    shared_examples "cancels hwr mail tasks" do
      it "cancels open HearingWithdrawalRequestMailTasks" do
        expect(hwr.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(child_hwr.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(child_hwr.cancelled_by).to eq(user)
        expect(child_hwr.instructions.last).to eq(
          "##### REASON FOR CANCELLATION:\n" \
          "Hearing withdrawn when #{task.type} was completed on #{formatted_date}"
        )
      end
    end

    context "hearing withdrawn through AssignHearingDispositionTask#cancel!" do
      let(:task) { disposition_task }

      before do
        task.hearing.update!(disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled)
        task.cancel!
        hwr.reload
      end

      include_examples "cancels hwr mail tasks"
    end

    context "hearing withdrawn through #update_from_params" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          instructions: "instructions"
        }
      end
      let(:business_payloads) do
        {
          values: {
            disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled
          }
        }
      end

      shared_context "call #update_from_params with business_payloads" do
        before do
          params[:business_payloads] = business_payloads
          task.update_from_params(params, user)
          hwr.reload
        end
      end

      context "hearing withdrawn through AssignHearingDispositionTask#update_from_params" do
        let(:task) { disposition_task }

        include_context "call #update_from_params with business_payloads"
        include_examples "cancels hwr mail tasks"
      end

      context "hearing withdrawn through ChangeHearingDispositionTask#update_from_params" do
        let(:task) { create(:change_hearing_disposition_task, parent: disposition_task.parent) }

        include_context "call #update_from_params with business_payloads"
        include_examples "cancels hwr mail tasks"
      end

      context "hearing withdrawn through ScheduleHearingTask#update_from_params" do
        let(:hwr) { create(:hearing_withdrawal_request_mail_task, :withdrawal_request_with_unscheduled_hearing) }
        let(:task) { appeal.tasks.of_type(ScheduleHearingTask.name).first }

        before do
          allow(task).to receive(:verify_user_can_update!).with(user).and_return(true)
          task.update_from_params(params, user)
          hwr.reload
        end

        include_examples "cancels hwr mail tasks"
      end
    end
  end
end
