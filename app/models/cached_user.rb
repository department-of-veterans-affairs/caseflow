# frozen_string_literal: true

class CachedUser < ApplicationRecord
  self.table_name = "cached_user_attributes"
  self.primary_key = "sdomainid"

  class << self
    def sync_from_vacols
      VACOLS::Staff.find_each do |staff|
        # we set attributes both in find_or_create_by block for not-null constraints
        # on initial creation, and to update stale attributes
        cached_user = find_or_create_by(sdomainid: staff.sdomainid) do |cuser|
          cuser.sattyid = staff.sattyid
          cuser.svlj = staff.svlj
          cuser.slogid = staff.slogid
          cuser.stafkey = staff.stafkey
          cuser.sactive = staff.sactive
        end
        cached_user.sattyid = staff.sattyid
        cached_user.svlj = staff.svlj
        cached_user.slogid = staff.slogid
        cached_user.stafkey = staff.stafkey
        cached_user.sactive = staff.sactive
        cached_user.save! if cached_user.changed?
      end
    end
  end
end
