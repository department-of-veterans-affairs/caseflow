# frozen_string_literal: true

# cache VACOLS staff data in the Caseflow db for easier correlation
# between systems. Best use case is SQL joins for metrics/reporting.

# For future work: some methods in app/repositories/user_repository.rb might be able to
# take advantage of this table, rather than using the Redis cache of VACOLS::Staff.

class CachedUser < CaseflowRecord
  self.table_name = "cached_user_attributes"
  self.primary_key = "sdomainid"

  class << self
    def sync_from_vacols
      VACOLS::Staff.having_css_id.find_each do |staff|
        # we set attributes both in find_or_create_by block for not-null constraints
        # on initial creation, and to update stale attributes
        cached_user = find_or_create_by(sdomainid: staff.sdomainid) do |cuser|
          cuser.sync_with_staff(staff)
        end
        cached_user.sync_with_staff(staff)
        cached_user.save! if cached_user.changed?
      end
    end

    def staff_column_names
      @staff_column_names ||= column_names.select { |attr| attr =~ /^s/ }
    end
  end

  def sync_with_staff(staff)
    staff_attributes = staff.attributes.select { |attr| CachedUser.staff_column_names.include?(attr) }
    assign_attributes(staff_attributes)
  end

  def full_name
    FullName.new(snamef, "", snamel).formatted(:readable_full)
  end
end
