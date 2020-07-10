# frozen_string_literal: true

class ETL::HearingSyncer < ETL::Syncer
  def origin_class
    ::Hearing
  end

  def target_class
    ETL::Hearing
  end

  def filter?(original)
    original.appeal.blank?
  end
end
