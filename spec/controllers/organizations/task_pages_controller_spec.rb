# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

describe Organizations::TaskPagesController, :postgres, type: :controller do
  let(:organization) { create(:organization) }
  let(:url) { organization.url }

  let(:user) { create(:user) }

  before do
    OrganizationsUser.add_user_to_organization(user, organization)
    User.authenticate!(user: user)
  end

  describe "GET organization/:organization_url/task_pages" do
    context "when user is member of the organization and the organization has tasks" do
      let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
      let(:task_count) { 4 }

      before { create_list(:generic_task, task_count, assigned_to: organization) }

      it "returns correct number of tasks" do
        get(:index, params: { organization_url: url, tab: tab_name })
        expect(response.status).to eq(200)
        response_body = JSON.parse(response.body)["tasks"]["data"]
        expect(response_body.size).to eq(task_count)
      end
    end
  end
end
