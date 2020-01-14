# frozen_string_literal: true

class ETL::UserSyncer < ETL::Syncer
  def origin_class
    ::User
  end

  def target_class
    ETL::User
  end

  private

  def instances_needing_update
    return origin_class unless incremental?

    UsersUpdatedSinceQuery.new(since_date: since).call
  end
end
