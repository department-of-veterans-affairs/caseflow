# frozen_string_literal: true

class ETL::LegacyHearingSyncer < ETL::Syncer
  def origin_class
    ::LegacyHearing
  end

  def target_class
    ETL::LegacyHearing
  end

  def filter?(original)
    original.appeal.blank?
  end
end
