# frozen_string_literal: true

class CachedAppeal < ApplicationRecord
  self.table_name = "cached_appeal_attributes"

  def self.task_table_join_clause
    "left join cached_appeal_attributes "\
    "on cached_appeal_attributes.appeal_id = tasks.appeal_id "\
    "and cached_appeal_attributes.appeal_type = tasks.appeal_type"
  end
end
