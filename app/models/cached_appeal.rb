# frozen_string_literal: true

class CachedAppeal < CaseflowRecord
  self.table_name = "cached_appeal_attributes"

  def self.left_join_from_tasks_clause
    "left join #{CachedAppeal.table_name} "\
    "on #{CachedAppeal.table_name}.appeal_id = #{Task.table_name}.appeal_id "\
    "and #{CachedAppeal.table_name}.appeal_type = #{Task.table_name}.appeal_type"
  end
end
