# frozen_string_literal: true

describe FetchAllActiveLegacyAppealsJob do
	subject { FetchAllActiveLegacyAppealsJob.new }
	describe "find_active_legacy_appeals" do
	let!(:assigned_tasks) do
		Array.new(6) { create(:task, type: "RootTask") }
	end
	let!(:on_hold_tasks) do
		Array.new(6) { create(:task, :on_hold, type: "RootTask") }
	end
	let!(:in_progress_tasks) do
		Array.new(6) { create(:task, :in_progress, type: "RootTask") }
	end
	let!(:completed_tasks) do
		Array.new(6) { create(:task, type: "RootTask") }
	end
	let!(:cancelled_tasks) do
		Array.new(6) { create(:task, type: "RootTask") }
	end
	let!(:ama_tasks) do
		Array.new(10) { create(:task, type: "RootTask") }
	end
	let!(:completed_root_tasks) do
		Array.new(3) { create(:task) }
	end
	  context "When all Tasks in DB are Root Tasks for Active Legacy Appeals" do
			it "All of the tasks will be fetched" do
				byebug
				expect(subject.send(:find_active_legacy_appeals).count).to eq(ama_tasks.count)
				# subject.find_active_legacy_appeals
			end
	  end
		# before { Task.last(status: Constants.TASK_STATUSES.completed) }
		context "When one of the RootTasks is completed" do
			it "Only active tasks will be fetched" do
				byebug
				expect(subject.send(:find_active_legacy_appeals).count).to eq(completed_tasks.count)
		  end
		end
	end
end
