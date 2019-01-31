describe TrackVeteranTask do
  let(:vso) { FactoryBot.create(:vso) }
  let(:root_task) { FactoryBot.create(:root_task) }
  let(:tracking_task) do
    FactoryBot.create(
      :track_veteran_task,
      parent: root_task,
      appeal: root_task.appeal,
      assigned_to: vso
    )
  end

  describe ".available_actions" do
    it "should never have available_actions" do
      expect(tracking_task.available_actions(vso)).to eq([])
    end
  end

  describe ".hide_from_queue_table_view" do
    it "should always be hidden from queue table view" do
      expect(tracking_task.hide_from_queue_table_view).to eq(true)
    end
  end

  describe ".hide_from_case_timeline" do
    it "should always be hidden from case timeline" do
      expect(tracking_task.hide_from_case_timeline).to eq(true)
    end
  end

  describe ".hide_from_task_snapshot" do
    it "should always be hidden from task snapshot" do
      expect(tracking_task.hide_from_case_timeline).to eq(true)
    end
  end
end
