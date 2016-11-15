describe ReassignOldTasksJob do
  before do
    reset_application!
    @appeal = Appeal.create(vacols_id: '1')
    @user = User.create(station_id: '123', css_id: 'abc')
    @unfinished_task = EstablishClaim.create(appeal_id: @appeal.id).assign(@user)
    #@finished_task = EstablishClaim.create(appeal_id: @appeal.id).completed!(2)
  end

  context ".perform" do
    it "closes unfinished tasks", focus: true do
      expect(EstablishClaim.count).to eq(1)
      ReassignOldTasksJob.perform_now
      expect(EstablishClaim.count).to eq(2)
      expect(@unfinished_task.complete?).to be_truthy 
    end
  end

end
