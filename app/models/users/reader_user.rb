class ReaderUser < ActiveRecord::Base
  belongs_to :user

  class << self
    def all_by_documents_fetched_at(limit = 10)
      # at this point, let's also make sure that we've created ReaderUser records
      create_reader_user_details(limit)

      ReaderUser
        .all
        .where("appeals_docs_fetched_at <= ? " \
               "OR appeals_docs_fetched_at IS NULL", 24.hours.ago)
        .order("appeals_docs_fetched_at IS NULL DESC, appeals_docs_fetched_at ASC")
        .limit(limit)
    end

    def create_reader_user_details(limit = 10)
      # find all users that don't have reader details
      # create ReaderUser records for these users
      all_reader_users_without_details(limit).each do |user|
        ReaderUser.create(user_id: user.id)
      end
    end

    def all_reader_users_without_details(limit = 10)
      User.joins("LEFT JOIN reader_users ON users.id=reader_users.user_id")
          .where("'Reader' = ANY(roles)")
          .where(reader_users: { user_id: nil })
          .limit(limit)
    end
  end
end
