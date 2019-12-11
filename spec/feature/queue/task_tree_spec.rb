# frozen_string_literal: true

feature "Task Tree", :all_dbs do
  context "attorney user with assigned tasks" do
    let(:attorney_user) { create(:user) }

    let(:appeal) { create(:appeal, :with_schedule_hearing_tasks, :ready_for_distribution) }

    let!(:attorney_task) do
      create(
        :ama_attorney_task,
        :on_hold,
        appeal: appeal,
        assigned_to: attorney_user,
        placed_on_hold_at: 2.days.ago
      )
    end

    before do
      User.authenticate!(user: attorney_user)
      visit "/appeals/#{appeal.external_id}/task_tree"
    end

    it "shows dynamic task tree" do
      expect(page).to have_content(appeal.veteran_full_name)
      expect(page).to have_content("RootTask")
    end
  end
end
