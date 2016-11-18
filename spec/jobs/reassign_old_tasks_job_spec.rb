describe ReassignOldTasksJob do
  before do
    reset_application!
  end
  let!(:appeal) { Appeal.create(vacols_id: "1") }
  let!(:user)   { User.create(station_id: "123", css_id: "abc") }
  let!(:unfinished_task) { EstablishClaim.create(appeal_id: appeal.id).assign!(user) }
  let!(:status_code) { Task.completion_status_code(:expired) }
  let!(:finished_task) do
    EstablishClaim.create(appeal_id:
    appeal.id).completed!(status_code)
  end

  context ".perform" do
    it "closes unfinished tasks" do
      expect(EstablishClaim.count).to eq(2)
      ReassignOldTasksJob.perform_now
      expect(EstablishClaim.count).to eq(3)
      expect(unfinished_task.reload.complete?).to be_truthy
    end
  end
end
