# frozen_string_literal: true

describe RetrieveDocumentsForReaderJob, :postgres do
  context ".perform" do
    context "a user exists who have been recently active" do
      let!(:active_user1) do
        create(:user, last_login_at: 3.days.ago, efolder_documents_fetched_at: 25.hours.ago)
      end
      let!(:active_user2) do
        create(:user, last_login_at: 3.days.ago, efolder_documents_fetched_at: 26.hours.ago)
      end
      let!(:active_user3) do
        create(:user, last_login_at: 3.days.ago, efolder_documents_fetched_at: 5.hours.ago)
      end
      let!(:active_user4) do
        create(:user, last_login_at: 3.days.ago)
      end
      let!(:inactive_user) do
        create(:user, last_login_at: 3.months.ago)
      end

      context "if there are active and inactive users" do
        it "should only run the job for the active user with expired or nil efolder_documents_fetched_at" do
          users = []
          allow(FetchDocumentsForReaderUserJob).to receive(:perform_later) { |user| users << user }
          RetrieveDocumentsForReaderJob.perform_now
          expect(users).to match_array([active_user1, active_user2, active_user4])
        end
      end
    end
  end
end
