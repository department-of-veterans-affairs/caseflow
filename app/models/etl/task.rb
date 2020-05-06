# frozen_string_literal: true

# transformed Task model, with denormalized User/Org attributes

class ETL::Task < ETL::Record
  belongs_to :appeal, primary_key: :appeal_id, foreign_key: :appeal_id, class_name: "ETL::Appeal"

  class << self
    def origin_primary_key
      :task_id
    end

    private

    def fetch_assigned_to(original)
      return org_cache(original.assigned_to_id) if original.assigned_to_type == "Organization"

      return user_cache(original.assigned_to_id) if original.assigned_to_type == "User"

      fail "Unknown assigned_to_type #{original.assigned_to_type}"
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)
      # memoize to save SQL calls
      assigned_to = fetch_assigned_to(original)
      assigned_by = user_cache(original.assigned_by_id)

      target.appeal_id = original.appeal_id
      target.appeal_type = original.appeal_type
      target.assigned_at = original.assigned_at
      target.assigned_by_id = assigned_by&.id
      target.assigned_by_user_css_id = assigned_by&.css_id
      target.assigned_by_user_full_name = assigned_by&.full_name
      target.assigned_by_user_sattyid = assigned_by&.vacols_user&.sattyid
      target.assigned_to_id = assigned_to.id
      target.assigned_to_org_name = assigned_to.is_a?(Organization) ? assigned_to.name : nil
      target.assigned_to_org_type = assigned_to.is_a?(Organization) ? assigned_to.type : nil
      target.assigned_to_type = original.assigned_to_type
      target.assigned_to_user_css_id = assigned_to.is_a?(User) ? assigned_to.css_id : nil
      target.assigned_to_user_full_name = assigned_to.is_a?(User) ? assigned_to.full_name : nil
      target.assigned_to_user_sattyid = assigned_to.is_a?(User) ? assigned_to.vacols_user&.sattyid : nil
      target.closed_at = original.closed_at
      target.instructions = original.instructions
      target.parent_id = original.parent_id
      target.placed_on_hold_at = original.placed_on_hold_at
      target.started_at = original.started_at
      target.task_created_at = original.created_at
      target.task_id = original.id
      target.task_status = original.status
      target.task_type = original.type
      target.task_updated_at = original.updated_at

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
