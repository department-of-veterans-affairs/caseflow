# frozen_string_literal: true

class ETL::RemandReasonSyncer < ETL::Syncer
  def origin_class
    ::RemandReason
  end

  def target_class
    ETL::RemandReason
  end
end
