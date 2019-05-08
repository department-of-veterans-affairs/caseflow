# frozen_string_literal: true

class ReaderUser < ApplicationRecord
  belongs_to :user

  class << self
    def all_by_documents_fetched_at(limit = 10)
      # at this point, let's also make sure that we've created ReaderUser records
      create_records(limit)

      ReaderUser
        .all
        .where("documents_fetched_at <= ? " \
               "OR documents_fetched_at IS NULL", 24.hours.ago)
        .order("documents_fetched_at IS NULL DESC, documents_fetched_at ASC")
        .limit(limit)
    end

    def create_records(limit = 10)
      # find all reader users that don't have reader_user records
      all_without_records(limit).each do |user|
        # create ReaderUser records for these users
        ReaderUser.create(user_id: user.id)
      end
    end

    def all_without_records(limit = 10)
      User.joins("LEFT JOIN reader_users ON users.id=reader_users.user_id")
        .where("'Reader' = ANY(roles)")
        .where(reader_users: { user_id: nil })
        .limit(limit)
    end
  end
end
