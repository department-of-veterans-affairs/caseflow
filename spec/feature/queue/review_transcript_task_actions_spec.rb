# frozen_string_literal: true

RSpec.feature "Case Details page ReviewTranscriptTask actions" do
  let(:appeal) { create(:appeal) }
  let(:hearing_user) { create(:user) }

  describe "cancel task" do
    before do
      HearingAdmin.singleton.add_user(hearing_user)
      User.authenticate!(user: hearing_user)
      @task = ReviewTranscriptTask.create(
        appeal: appeal,
        assigned_to: hearing_user,
        assigned_by: User.system_user,
        parent: appeal.root_task,
        status: "assigned"
      )
    end
    it "cancels the ReviewTranscriptTask" do
      visit "/queue/appeals/#{appeal.uuid}"

      click_dropdown(id: "available-actions", text: "Cancel task")
      fill_in "Please provide context and instructions for this action", with: "The are test notes, from our tester."
      click_on("Cancel task")

      expect(page).to have_content("ReviewTranscriptTask cancelled")

      @task.reload
      expect(@task.status).to eq("cancelled")
    end
  end
end
