# frozen_string_literal: true

class ReaderUser < ApplicationRecord
  belongs_to :user

  DEFAULT_USERS_LIMIT = 5

  class << self
    def all_by_documents_fetched_at
      # At this point, let's also make sure that we've created Reader user records
      create_records
      delete_records

      ReaderUser
        .all
        .where("documents_fetched_at <= ? " \
               "OR documents_fetched_at IS NULL", 24.hours.ago)
        .order("documents_fetched_at IS NULL DESC, documents_fetched_at ASC")
        .limit(DEFAULT_USERS_LIMIT)
    end

    def create_records
      # Find all reader users that don't have Reader user records
      all_without_records.each do |user|
        # Create ReaderUser records for these users
        ReaderUser.create(user_id: user.id)
      end
    end

    # Delete Reader user records that have not been active
    def delete_records
      ReaderUser.joins("LEFT JOIN users ON users.id=reader_users.user_id")
        .where("last_login_at < ?", 1.week.ago)
        .limit(DEFAULT_USERS_LIMIT).map(&:delete)
    end

    # Search through users who have been active for the past month
    def all_without_records
      User.joins("LEFT JOIN reader_users ON users.id=reader_users.user_id")
        .where("last_login_at >= ?", 1.week.ago)
        .where(reader_users: { user_id: nil })
        .limit(DEFAULT_USERS_LIMIT)
    end
  end
end
