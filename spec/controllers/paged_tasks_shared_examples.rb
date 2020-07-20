# frozen_string_literal: true

# Shared examples for user and organization task pages controllers

shared_examples "paged assignee tasks" do
  let(:tab_name) { assignee.class.default_active_tab }
  let(:task_count) { 4 }

  before do
    create_list(:ama_task, task_count, assigned_to: assignee)
    allow(assignee).to receive(:use_task_pages_api?).and_return(true)
  end

  subject do
    get(:index, params: params)
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
    expect(subject["task_page_count"]).to eq((task_count.to_f / TaskPager::TASKS_PER_PAGE).ceil)
  end

  it "returns correct total_task_count" do
    expect(subject["total_task_count"]).to eq(task_count)
  end

  context "when the number of tasks are greater than the tasks per page" do
    let(:number_of_pages) { 2 }
    let(:task_count) { TaskPager::TASKS_PER_PAGE * number_of_pages }

    it "only returns the tasks per page" do
      expect(subject["tasks"]["data"].size).to eq(TaskPager::TASKS_PER_PAGE)
      expect(subject["task_page_count"]).to eq(number_of_pages)
      expect(subject["total_task_count"]).to eq(task_count)
    end
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
    allow_any_instance_of(TaskPaginationConcern).to receive(:json_tasks).and_return([])

    subject
  end
end
