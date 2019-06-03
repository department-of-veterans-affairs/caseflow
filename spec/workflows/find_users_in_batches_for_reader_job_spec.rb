# frozen_string_literal: true

require "rails_helper"

describe FindUsersInBatchesForReaderJob do
  describe "#process" do
    let!(:active_user1) do
      create(:user, last_login_at: 3.days.ago, efolder_documents_fetched_at: 25.hours.ago )
    end
    let!(:active_user2) do
      create(:user, last_login_at: 3.days.ago, efolder_documents_fetched_at: 26.hours.ago )
    end
    let!(:active_user3) do
      create(:user, last_login_at: 3.days.ago, efolder_documents_fetched_at: 5.hours.ago )
    end
    let!(:active_user4) do
      create(:user, last_login_at: 3.days.ago)
    end
    let!(:inactive_user) do
      create(:user, last_login_at: 3.months.ago )
    end

    subject { FindUsersInBatchesForReaderJob.process }

    it "should return active user with expired or nil efolder_documents_fetched_at" do
      # should first process the user with nil efolder_documents_fetched_at
      expect(subject[0].id).to eq active_user4.id
      # should then process users with the oldest efolder_documents_fetched_at
      expect(subject[1].id).to eq active_user2.id
      expect(subject[2].id).to eq active_user1.id
    end
  end
end