# frozen_string_literal: true

class ETL::AppealSyncer < ETL::Syncer
  def origin_class
    ::Appeal
  end

  def target_class
    ETL::Appeal
  end

  private

  def instances_needing_update
    return origin_class unless incremental?

    AppealsUpdatedSinceQuery.new(since_date: since).call
  end
end
