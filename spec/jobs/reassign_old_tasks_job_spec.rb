describe ReassignOldTasksJob do
  before do
    reset_application!
    @appeal = Appeal.create(vacols_id: "1")
    @user = User.create(station_id: "123", css_id: "abc")
    @unfinished_task = EstablishClaim.create(appeal_id: @appeal.id).assign(@user)
    status_code = Task.completion_status_code("Cancelled by System")
    @finished_task = EstablishClaim.create(appeal_id: @appeal.id).completed!(status_code)
  end

  context ".perform" do
    it "closes unfinished tasks" do
      expect(EstablishClaim.count).to eq(2)
      ReassignOldTasksJob.perform_now
      expect(EstablishClaim.count).to eq(3)
      expect(@unfinished_task.reload.complete?).to be_truthy
    end
  end
end
