# frozen_string_literal: true

describe FetchAllActiveAmaAppealsJob, type: :job do
  include ActiveJob::TestHelper
  
  before do
    subject { FetchAllActiveAmaAppealsJob.new }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "returns an array of all active ama appeals" do
    expect(subject).to receive(:find_active_ama_appeals)
    subject.perform
  end

  it "is in the correct queue" do
    queue_name = "caseflow_test_low_priority"
    expect(subject.new.queue_name).to eq(queue_name)
  end

  describe ".perform" do
    let(:current_user) { create(:user, roles: ["System Admin"]) }
    let(:ama_appeals) { create_list(:ama_appeal, 10) }
    let(:appeal) { create(:appeal) }
    # rubocop:disable Style/BlockDelimiters
    let(:tasks) {
      create_list(:task, 20) do |task, index|
        id = index + 1
        task.update!(id: id)
        if id % 5 == 0
          task.update!(status: "assigned")
        else
          task.update!(status: "completed")
        end
        if id.even?
          task.update!(appeal_type: "Appeal", ama_appeal: ama_appeals[index / 2])
        else
          task.update!(appeal_type: "Appeal", appeal: appeal)
        end
      end
    }
    let(:all_active_claims) { [ama_appeal[9], ama_appeal[4]] }
    # rubocop:enable Style/BlockDelimiters
    describe "a message is sent to the queue" do
      subject(:job) { SendNotificationJob.perform_later }
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end
      it "has the correct amount of claims listed" do
        ama_appeals
        tasks
        perform_enqueued_jobs do
          result = subject.perform_now
          expect(result.size).to eq(2)
        end
      end
      it "is returns correct claims" do
        ama_appeals
        tasks
        perform_enqueued_jobs do
          result = subject.perform_now
          expect(result).to eq(all_active_claims)
        end
      end
    end
  end
end
