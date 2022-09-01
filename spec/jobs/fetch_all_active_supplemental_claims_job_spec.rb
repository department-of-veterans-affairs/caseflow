# frozen_string_literal: true

describe FetchAllActiveSupplementalClaimsJob, type: :job do
  include ActiveJob::TestHelper

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "it is the correct queue" do
    queue_name = "caseflow_test_low_priority"
    expect(FetchAllActiveSupplementalClaimsJob.new.queue_name).to eq(queue_name)
  end

  context ".perform" do
    let(:current_user) { create(:user, roles: ["System Admin"]) }
    let(:supplemental_claims) { create_list(:supplemental_claim, 10) }
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
          task.update!(appeal_type: "SupplementalClaim", supplemental_claim: supplemental_claims[index / 2])
        else
          task.update!(appeal_type: "SupplementalClaim", appeal: appeal)
        end
      end
    }
    let(:all_active_claims) { [supplemental_claims[9], supplemental_claims[4]] }
    # rubocop:enable Style/BlockDelimiters

    describe "a message is sent to queue" do
      subject(:job) { SendNotificationJob.perform_later }
      it "has one message in queue" do
        expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
      end

      it "it has the correct amount of claims listed" do
        supplemental_claims
        tasks
        perform_enqueued_jobs do
          result = FetchAllActiveSupplementalClaimsJob.perform_now
          expect(result.size).to eq(2)
        end
      end

      it "is returns correct claims" do
        supplemental_claims
        tasks
        perform_enqueued_jobs do
          result = FetchAllActiveSupplementalClaimsJob.perform_now
          expect(result).to eq(all_active_claims)
        end
      end
    end
  end
end
