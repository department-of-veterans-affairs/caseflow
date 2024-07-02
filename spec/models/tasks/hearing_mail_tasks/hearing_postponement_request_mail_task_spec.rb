# frozen_string_literal: true

describe HearingPostponementRequestMailTask, :postgres do
  let(:user) { create(:user) }
  let(:hpr) { create(:hearing_postponement_request_mail_task, :postponement_request_with_scheduled_hearing) }

  describe "#available_actions" do
    let(:task_actions) do
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.COMPLETE_AND_POSTPONE.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
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

      it "returns appropriate task actions" do
        expect(hpr.available_actions(user).length).to eq(5)
        expect(hpr.available_actions(user)).to eq(task_actions)
      end
    end
  end

  describe "#update_from_params" do
    let(:user) { create(:user) }
    let(:parent_hpr) { create(:hearing_postponement_request_mail_task, :postponement_request_with_scheduled_hearing) }
    let!(:hpr) { parent_hpr.children.first }
    let(:params) do
      {
        status: "completed",
        business_payloads: {
          values: {
            disposition: "postponed",
            after_disposition_update: { action: "schedule_later" },
            date_of_ruling: "2024-01-10",
            instructions: "test",
            granted: true
          }
        }
      }
    end
    let(:appeal) { hpr.appeal }
    let(:disposition_task) { appeal.tasks.of_type(AssignHearingDispositionTask.name).first }
    let(:disposition_task_status) { "assigned" }
    let(:schedule_task) { appeal.tasks.of_type(ScheduleHearingTask.name).first }
    let(:hearing_task) { hpr.hearing_task }
    let(:hearing) { disposition_task.hearing }

    subject { hpr.update_from_params(params, user) }

    shared_examples "whether granted or denied" do
      it "completes HPR parent and child task" do
        expect(parent_hpr.status).to eq("on_hold")
        expect(hpr.status).to eq("assigned")
        subject
        expect(parent_hpr.status).to eq("completed")
        expect(hpr.status).to eq("completed")
      end
    end

    shared_examples "whether reschedule or schedule later" do
      include_examples "whether granted or denied"

      it "cancels and recreates HearingTask" do
        original_hearing_task = hearing_task
        expect(original_hearing_task.status).to eq("on_hold")
        expect { subject }.to change(HearingTask, :count).by(1)
        expect(original_hearing_task.reload.status).to eq("cancelled")
      end
    end

    context "postponement granted with schedule later action" do
      context "for appeal with open AssignHearingDispositionTask" do
        shared_examples "whether hearing upcoming or in past" do
          include_examples "whether reschedule or schedule later"

          it "cancels AssignHearingDispositionTask and creates new ScheduleHearingTask" do
            expect(disposition_task.status).to eq(disposition_task_status)
            expect { subject }.to change(ScheduleHearingTask, :count).by(1)
            expect(disposition_task.reload.status).to eq("cancelled")
          end
        end

        context "and upcoming hearing" do
          include_examples "whether hearing upcoming or in past"

          it "updates previous hearing's disposition to postponed" do
            expect(hearing.disposition).to be_nil
            subject
            expect(hearing.reload.disposition).to eq("postponed")
          end
        end

        context "and hearing marked no show and NoShowHearingTask created" do
          let(:disposition_task_status) { "on_hold" }

          before do
            hearing.update(disposition: "no_show")
            disposition_task.no_show!
            allow(hpr).to receive(:hearing_scheduled_and_awaiting_disposition?).and_return(false)
          end

          include_examples "whether hearing upcoming or in past"

          it "doesn't update previous hearing's disposition" do
            expect(hearing.disposition).to eq("no_show")
            subject
            expect(hearing.reload.disposition).to eq("no_show")
          end
        end
      end

      context "for appeal with active ScheduleHearingTask" do
        let(:parent_hpr) do
          create(:hearing_postponement_request_mail_task, :postponement_request_with_unscheduled_hearing)
        end

        include_examples "whether reschedule or schedule later"

        it "cancels ScheduleHearingTask and creates new ScheduleHearingTask" do
          original_schedule_task = schedule_task
          expect(original_schedule_task.status).to eq("assigned")
          expect { subject }.to change(ScheduleHearingTask, :count).by(1)
          expect(original_schedule_task.reload.status).to eq("cancelled")
        end
      end
    end

    context "postponement granted with reschedule immediately action" do
      let(:virtual_hearing_day) do
        create(
          :hearing_day,
          request_type: HearingDay::REQUEST_TYPES[:virtual],
          scheduled_for: Time.zone.today + 160.days,
          regional_office: "RO39"
        )
      end
      let(:params) do
        {
          status: "cancelled",
          business_payloads: {
            values: {
              disposition: "postponed",
              after_disposition_update: {
                action: "reschedule",
                new_hearing_attrs: {
                  email_recipients: {
                    appellant_tz: "America/Los_Angeles",
                    representative_tz: "America/Los_Angeles",
                    appellant_email: "test@test.com"
                  },
                  scheduled_time_string: "09:00 AM America/Los_Angeles",
                  hearing_day_id: virtual_hearing_day.id,
                  hearing_location: nil,
                  virtual_hearing_attributes: {
                    appellant_tz: "America/Los_Angeles",
                    representative_tz: "America/Los_Angeles",
                    appellant_email: "test@test.com"
                  }
                }
              },
              date_of_ruling: "2024-01-10",
              instructions: "test",
              granted: true
            }
          }
        }
      end

      before do
        RequestStore[:current_user] = user
      end

      context "for appeal with open AssignHearingDispositionTask" do
        shared_examples "whether hearing upcoming or in past" do
          include_examples "whether reschedule or schedule later"

          it "cancels AssignHearingDispositionTask and creates new AssignHearingDispositionTask" do
            expect(disposition_task.status).to eq(disposition_task_status)
            expect { subject }.to change(AssignHearingDispositionTask, :count).by(1)
            expect(disposition_task.reload.status).to eq("cancelled")
          end
        end

        context "and hearing upcoming" do
          include_examples "whether hearing upcoming or in past"

          it "updates previous hearing's disposition to postponed" do
            expect(hearing.disposition).to be_nil
            subject
            expect(hearing.reload.disposition).to eq("postponed")
          end
        end

        context "and hearing marked no show and NoShowHearingTask created" do
          let(:disposition_task_status) { "on_hold" }

          before do
            hearing.update(disposition: "no_show")
            disposition_task.no_show!
            allow(hpr).to receive(:hearing_scheduled_and_awaiting_disposition?).and_return(false)
          end

          include_examples "whether hearing upcoming or in past"

          it "doesn't update previous hearing's disposition" do
            expect(hearing.disposition).to eq("no_show")
            subject
            expect(hearing.reload.disposition).to eq("no_show")
          end
        end
      end
    end
  end

  describe "hearing postponed through completion of alternate task" do
    let(:appeal) { hpr.appeal }
    let(:child_hpr) { hpr.children.first }
    let(:formatted_date) { hpr.updated_at.strftime("%m/%d/%Y") }
    let(:disposition_task) { appeal.tasks.where(type: AssignHearingDispositionTask.name).first }

    before do
      HearingAdmin.singleton.add_user(user)
      RequestStore[:current_user] = user
    end

    shared_examples "cancels hpr mail tasks" do
      it "cancels open HearingPostponementRequestMailTasks" do
        expect(hpr.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(child_hpr.status).to eq(Constants.TASK_STATUSES.cancelled)
        expect(child_hpr.cancelled_by).to eq(user)
        expect(child_hpr.instructions.last).to eq(
          "##### REASON FOR CANCELLATION:\n" \
          "Hearing postponed when #{task.type} was completed on #{formatted_date}"
        )
      end
    end

    context "hearing postponed through AssignHearingDispositionTask#postpone!" do
      let(:task) { disposition_task }

      before do
        task.hearing.update!(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
        task.postpone!
        hpr.reload
      end

      include_examples "cancels hpr mail tasks"
    end

    context "hearing postponed through NoShowHearingTask#reschedule_hearing" do
      let(:task) { appeal.tasks.where(type: NoShowHearingTask.name).first }

      before do
        disposition_task.hearing.update!(disposition: Constants.HEARING_DISPOSITION_TYPES.no_show)
        disposition_task.no_show!
        task.reschedule_hearing
        hpr.reload
      end

      include_examples "cancels hpr mail tasks"
    end

    context "hearing postponed through #update_from_params" do
      let(:params) do
        {
          status: Constants.TASK_STATUSES.cancelled,
          instructions: "instructions",
          business_payloads: {
            values: {
              disposition: Constants.HEARING_DISPOSITION_TYPES.postponed,
              after_disposition_update: { action: "schedule_later" }
            }
          }
        }
      end

      before do
        task.update_from_params(params, user)
        hpr.reload
      end

      context "hearing postponed through AssignHearingDispositionTask#update_from_params" do
        let(:task) { disposition_task }

        include_examples "cancels hpr mail tasks"
      end

      context "hearing postponed through ChangeHearingDispositionTask#update_from_params" do
        let(:task) { create(:change_hearing_disposition_task, parent: disposition_task.parent) }

        include_examples "cancels hpr mail tasks"
      end
    end
  end
end
