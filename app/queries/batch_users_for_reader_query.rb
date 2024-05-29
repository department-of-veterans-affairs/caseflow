# frozen_string_literal: true

class BatchUsersForReaderQuery
  DEFAULT_USERS_LIMIT = 5

  def self.process
    User.where("(efolder_documents_fetched_at <= ? " \
               "OR efolder_documents_fetched_at IS NULL) " \
               "AND last_login_at >= ?", 24.hours.ago, 1.week.ago)
      .order(Arel.sql("efolder_documents_fetched_at IS NULL DESC, efolder_documents_fetched_at ASC"))
      .limit(DEFAULT_USERS_LIMIT)
  end
end
