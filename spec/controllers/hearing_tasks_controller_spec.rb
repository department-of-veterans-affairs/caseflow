# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.describe HearingTasksController, :all_dbs, type: :controller do
  before do
    user = create(:user, full_name: "Hearings User", station_id: 101, roles: ["System Admin"])
    HearingsManagement.singleton.add_user(user)
    MailTeam.singleton.add_user(user)
    TranscriptionTeam.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  describe "POST /schedule_veteran" do
    context "for cases with an open ScheduleHearingTask" do
      let(:schedule_hearing_task) { create(:schedule_hearing_task) }
      let(:hearing_day) { create(:hearing_day) }
      let(:params) do
        {
          id: schedule_hearing_task.id,
          task: {
            status: Constants.TASK_STATUSES.completed
          },
          hearing: {
            hearing_day_id: hearing_day.id,
            hearing_location_attrs: {
              facility_id: "vba_123"
            },
            scheduled_time_string: "08:30"
          }
        }
      end

      subject { post :schedule_veteran, params: params }

      it do
        subject
        expect(response.status).to eq 200
      end
    end
  end

  describe "POST /reschedule_no_show_hearing" do
    context "for cases with an open NoShowHearingTask" do
      let(:no_show_task) { create(:no_show_hearing_task) }
      let(:params) do
        {
          id: no_show_task.id,
          task: {
            status: Constants.TASK_STATUSES.completed
          }
        }
      end

      subject { post :reschedule_no_show_hearing, params: params }

      it do
        subject
        expect(response.status).to eq 200
      end
    end
  end

  describe "POST /create_change_hearing_disposition_task" do
    let!(:task) { nil }
    let!(:appeal) { create(:appeal) }
    let!(:params) do
      {
        id: task.id,
        task: {
          status: Constants.TASK_STATUSES.completed
        }
      }
    end

    subject { post :create_change_hearing_disposition_task, params: params }

    context "for cases with an open " do
      let!(:possible_tasks) do
        {
          AssignHearingDispositionTask: create(:assign_hearing_disposition_task),
          EvidenceSubmissionWindowTask: create(:evidence_submission_window_task),
          NoShowHearingTask: create(:no_show_hearing_task),
          TranscriptionTask: create(
            :transcription_task,
            parent: create(:assign_hearing_disposition_task, appeal: appeal),
            appeal: appeal
          )
        }
      end

      [
        :AssignHearingDispositionTask, :EvidenceSubmissionWindowTask,
        :NoShowHearingTask, :TranscriptionTask
      ].each do |task_for_example|
        context task_for_example.to_s do
          let(:task) { possible_tasks[task_for_example] }

          it do
            subject
            expect(response.status).to eq 200
          end
        end
      end
    end
  end

  describe "POST /create_change_previous_hearing_disposition_task" do
    context "for cases with an open ScheduleHearingTask where a previous hearing was cancelled or postponed" do
      let!(:appeal) { create(:appeal) }
      before do
        hearing = create(:hearing, appeal: appeal, disposition: "postponed")
        hearing_task = create(:hearing_task, appeal: appeal)
        AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, hearing_task, hearing)
        hearing_task.update(status: Constants.TASK_STATUSES.cancelled)
      end
      let!(:schedule_hearing_task) { create(:schedule_hearing_task, appeal: appeal) }
      let!(:appeal) { create(:appeal) }
      let!(:params) do
        {
          id: schedule_hearing_task.id,
          task: {
            status: Constants.TASK_STATUSES.cancelled
          }
        }
      end

      subject { post :create_change_previous_hearing_disposition_task, params: params }

      it do
        subject
        expect(response.status).to eq 200
      end
    end
  end
end
