# frozen_string_literal: true

describe BatchUsersForReaderQuery, :postgres do
  describe "#process" do
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

    subject { BatchUsersForReaderQuery.process }

    it "should return active user with expired or nil efolder_documents_fetched_at" do
      # should first process the user with nil efolder_documents_fetched_at
      # then should return users with the oldest efolder_documents_fetched_at
      expect(subject.to_a).to eq([active_user4, active_user2, active_user1])
    end
  end
end
