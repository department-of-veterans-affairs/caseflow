# frozen_string_literal: true

class ETL::TaskSyncer < ETL::Syncer
  def origin_class
    ::Task
  end

  def target_class
    ETL::Task
  end

  def filter?(original)
    original.appeal.blank?
  end
end
