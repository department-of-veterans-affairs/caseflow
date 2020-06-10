# frozen_string_literal: true

describe Organizations::TaskPagesController, :postgres, type: :controller do
  require_relative "../paged_tasks_shared_examples"

  let(:assignee) { create(:organization) }
  let(:url) { assignee.url }
  let(:params) { { organization_url: url, tab: tab_name } }

  let(:user) { create(:user) }

  before do
    assignee.add_user(user)
    User.authenticate!(user: user)
  end

  describe "GET organization/:organization_url/task_pages" do
    context "when user is member of the organization and the organization has tasks" do
      it_behaves_like "paged assignee tasks"
    end
  end
end
