# frozen_string_literal: true

class StaffFieldForOrganization < ApplicationRecord
  belongs_to :organization
  # :nocov:
  def filter_staff_records(records)
    # where.not() filters out nil values. We want to allow nil values and only disallow the excluded values.
    return records.where.not("#{name}": values).or(records.where("#{name}": nil)) if exclude?

    records.where("#{name}": values)
  end
  # :nocov:
end
