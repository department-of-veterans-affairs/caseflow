# frozen_string_literal: true

describe UserDedupService do
  let(:duplicate_css_id) { "TeSt_CsS_iD" }
  let!(:user) { create(:user, css_id: "TEST_CSS_ID") }
  let!(:duplicate_user) { create(:user, css_id: duplicate_css_id) }

  let!(:associated_hearing_day) { create(:hearing_day, judge_id: duplicate_user.id) }
  let!(:associated_task) { create(:task, assigned_to: duplicate_user) }
  let!(:associated_appeal_view) { DocumentView.create!(document_id: "123", user: duplicate_user) }

  describe "#merge_all_users_with_uppercased_user" do
    it "combines the users" do
      UserDedupService.new(user).merge_all_users_with_uppercased_user

      expect(associated_hearing_day.reload.judge_id).to eq(user.id)
      expect(associated_task.reload.assigned_to_id).to eq(user.id)
      expect(associated_appeal_view.reload.user_id).to eq(user.id)
    end
  end

  describe ".undo_change" do
    it "saves commands to undo the operation" do
      UserDedupService.new(user).merge_all_users_with_uppercased_user

      expect(associated_hearing_day.reload.judge_id).to eq(user.id)
      expect(associated_task.reload.assigned_to_id).to eq(user.id)
      expect(associated_appeal_view.reload.user_id).to eq(user.id)

      UserDedupService.new(user.reload).undo_change

      expect(associated_hearing_day.reload.judge_id).to eq(duplicate_user.id)
      expect(associated_task.reload.assigned_to_id).to eq(duplicate_user.id)
      expect(associated_appeal_view.reload.user_id).to eq(duplicate_user.id)

      expect(User.find(duplicate_user.id).css_id).to eq(duplicate_css_id)
    end
  end
end
