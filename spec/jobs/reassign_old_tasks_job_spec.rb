require "rails_helper"

describe ReassignOldTasksJob do
  let!(:appeal1) { Appeal.create(vacols_id: "1") }
  let!(:appeal2) { Appeal.create(vacols_id: "2") }
  let!(:user1) { User.create(station_id: "123", css_id: "abc") }
  let!(:user2) { User.create(station_id: "123", css_id: "def") }
  let!(:unfinished_task) { EstablishClaim.create(appeal_id: appeal1.id) }
  let!(:status_code) { Task.completion_status_code(:expired) }

  let!(:finished_task) do
    EstablishClaim.create(appeal_id: appeal2.id)
  end

  before do
    unfinished_task.assign!(:assigned, user1)
    unfinished_task.start!
    finished_task.assign!(:assigned, user2)
    finished_task.start!
    finished_task.complete!(:completed, status: status_code)
  end

  context ".perform" do
    it "closes unfinished tasks" do
      expect(EstablishClaim.count).to eq(2)
      ReassignOldTasksJob.perform_now
      expect(EstablishClaim.count).to eq(3)
      expect(unfinished_task.reload.completed?).to be_truthy
    end
  end
end
