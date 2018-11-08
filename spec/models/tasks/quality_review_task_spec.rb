describe QualityReviewTask do
  describe ".mark_as_complete!" do
    let(:root_task) { FactoryBot.create(:root_task) }

    it "should create a task for BVA dispatch and close the current task" do
      qr_task = QualityReviewTask.create_from_root_task(root_task)
      qr_task.mark_as_complete!

      expect(qr_task.status).to eq(Constants.TASK_STATUSES.completed)
      expect(root_task.children.select { |t| t.type == BvaDispatchTask.name }.count).to eq(1)
    end
  end
end
