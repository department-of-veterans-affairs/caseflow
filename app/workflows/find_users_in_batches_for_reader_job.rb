class FindUsersInBatchesForReaderJob
  DEFAULT_USERS_LIMIT = 5

  def self.process
  	User.where("(documents_fetched_at <= ? " \
               "OR documents_fetched_at IS NULL) " \
               "AND last_login_at >= ?", 24.hours.ago, 1.week.ago)
        .order("documents_fetched_at IS NULL DESC, documents_fetched_at ASC")
        .limit(DEFAULT_USERS_LIMIT)
  end
end