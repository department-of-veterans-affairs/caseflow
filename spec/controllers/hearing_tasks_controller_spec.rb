# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

RSpec.describe HearingTasksController, :all_dbs, type: :controller do
  before do
    user = create(:user, full_name: "Hearings User", station_id: 101, roles: ["System Admin"])
    HearingsManagement.singleton.add_user(user)
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
end
