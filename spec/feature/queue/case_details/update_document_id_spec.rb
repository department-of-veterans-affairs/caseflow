require "rails_helper"

feature "Updating Document ID" do
  context "Valid Document ID" do
    it "updates the Document ID and displays the new ID" do
      appeal = create(:appeal)
      user = create(:user)
      root_task = create(:root_task, appeal: appeal, assigned_to: user)
      attorney_task = create(
        :ama_attorney_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: user,
        completed_at: Time.zone.now - 4.days
      )
      attorney_task.update!(status: Constants.TASK_STATUSES.completed)
      create(:attorney_case_review, task_id: attorney_task.id, attorney: user)

      User.authenticate!(user: user)
      visit("/queue/appeals/#{appeal.external_id}")
      click_button "Edit"
      fill_in "Decision Document ID", with: "11111-22334455"
      click_button "Save"

      expect(page).to have_content "Document Id Saved!"
      expect(page).to have_content "11111-22334455"
    end
  end

  context "Invalid Document ID" do
    it "does not update the Document ID and displays an error" do
      appeal = create(:appeal)
      user = create(:user)
      root_task = create(:root_task, appeal: appeal, assigned_to: user)
      attorney_task = create(
        :ama_attorney_task,
        appeal: appeal,
        parent: root_task,
        assigned_to: user,
        completed_at: Time.zone.now - 4.days
      )
      attorney_task.update!(status: Constants.TASK_STATUSES.completed)
      create(
        :attorney_case_review,
        task_id: attorney_task.id,
        attorney: user,
        document_id: "12345678.1234"
      )

      User.authenticate!(user: user)
      visit("/queue/appeals/#{appeal.external_id}")
      click_button "Edit"
      fill_in "Decision Document ID", with: "123.123"
      click_button "Save"

      expect(page).to have_content "Draft Decision Document IDs must be in one of these formats:"
      expect(page).to have_content "12345678.1234"
    end
  end
end
