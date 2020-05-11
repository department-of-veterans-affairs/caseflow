# frozen_string_literal: true

describe Users::TaskPagesController, :postgres, type: :controller do
  require_relative "../paged_tasks_shared_examples"

  let(:assignee) { create(:user) }
  let(:url) { assignee.id }
  let(:params) { { user_id: url, tab: tab_name } }

  before do
    User.authenticate!(user: assignee)
  end

  describe "GET user/:user_id/task_pages" do
    it_behaves_like "paged assignee tasks"
  end
end
