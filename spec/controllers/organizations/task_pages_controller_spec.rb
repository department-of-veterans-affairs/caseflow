# frozen_string_literal: true

describe Organizations::TaskPagesController, :postgres, type: :controller do
  let(:organization) { create(:organization) }
  let(:url) { organization.url }

  let(:user) { create(:user) }

  before do
    organization.add_user(user)
    User.authenticate!(user: user)
  end

  describe "GET organization/:organization_url/task_pages" do
    context "when user is member of the organization and the organization has tasks" do
      let(:tab_name) { Constants.QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME }
      let(:task_count) { 4 }

      before { create_list(:ama_task, task_count, assigned_to: organization) }

      subject do
        get(:index, params: { organization_url: url, tab: tab_name })
        expect(response.status).to eq(200)
        JSON.parse(response.body)
      end

      it "returns correct elements of the response" do
        expect(subject.keys).to match_array(%w[tasks task_page_count total_task_count tasks_per_page])
      end

      it "returns correct number of tasks" do
        expect(subject["tasks"]["data"].size).to eq(task_count)
      end

      it "returns correct task_page_count" do
        expect(subject["task_page_count"]).to eq((task_count.to_f / TaskPager::TASKS_PER_PAGE.to_f).ceil)
      end

      it "returns correct total_task_count" do
        expect(subject["total_task_count"]).to eq(task_count)
      end

      it "returns correct tasks_per_page" do
        expect(subject["tasks_per_page"]).to eq(TaskPager::TASKS_PER_PAGE)
      end

      it "only instantiates TaskPager a single time" do
        task_pager = instance_double(TaskPager)
        expect(TaskPager).to receive(:new).and_return(task_pager).exactly(1).times

        expect(task_pager).to receive(:paged_tasks)
        expect(task_pager).to receive(:task_page_count)
        expect(task_pager).to receive(:total_task_count)

        # Prevent this call from actually firing since it will fail due to the instance_double.
        allow_any_instance_of(::Organizations::TaskPagesController).to receive(:json_tasks).and_return([])

        subject
      end
    end
  end
end
