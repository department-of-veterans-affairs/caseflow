# frozen_string_literal: true

# Match any User or CachedUser that have been updated since a baseline date.
#

class UsersUpdatedSinceQuery
  def initialize(since_date:)
    @since_date = since_date
  end

  def call
    build_query
  end

  private

  attr_reader :since_date

  def build_query
    User.left_joins(:vacols_user).distinct
      .where("users.updated_at >= ? OR cached_user_attributes.updated_at >= ?", since_date, since_date)
  end
end
