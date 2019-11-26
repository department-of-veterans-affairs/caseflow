# frozen_string_literal: true

# transformed User model, with VACOLS+Caseflow attributes

class ETL::User < ETL::Record
  class << self
    def sync_with_original(original)
      target = find_by_primary_key(original) || new
      merge_original_attributes_to_target(original, target)
    end

    def origin_primary_key
      :user_id
    end

    private

    def merge_original_attributes_to_target(original, target)
      target.user_id = original.id
      target.css_id = original.css_id
      target.email = original.email
      target.full_name = original.full_name
      target.last_login_at = original.last_login_at
      target.roles = original.roles
      target.selected_regional_office = original.selected_regional_office
      target.station_id = original.station_id
      target.status = original.status
      target.status_updated_at = original.status_updated_at

      target.sactive = original.vacols_user.sactive
      target.slogid = original.vacols_user.slogid
      target.stafkey = original.vacols_user.stafkey
      target.svlj = original.vacols_user.svlj

      target.created_at = original.created_at || original.vacols_user.created_at
      # let Rails set updated_at to now

      target
    end
  end
end
