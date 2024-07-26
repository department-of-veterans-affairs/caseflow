# frozen_string_literal: true

class VACOLS::Record < ApplicationRecord
  self.abstract_class = true

  establish_connection :vacols
  ActiveSupport.run_load_hooks(:active_record_vacols, VACOLS::Record)

  # This method calculates the appropriate date & timezone
  # necessary to get a relative date within vacols
  # `date_diff` will most commonly be the rails date helpers
  # example: relative_vacols_date(7.days)
  def self.relative_vacols_date(date_diff)
    rounded_current_time - date_diff
  end

  def self.rounded_current_time
    Time.use_zone(VacolsHelper::VACOLS_DEFAULT_TIMEZONE) do
      current_time = Time.zone.now

      # Round off hours, minutes, and seconds
      Time.zone.local(
        current_time.year,
        current_time.month,
        current_time.day
      )
    end
  end

  def self.current_user_slogid
    slogid = RequestStore.store[:current_user].vacols_uniq_id
    slogid.nil? ? "" : slogid.upcase
  end

  # AsciiString attribute type not applied to update_all() class method
  # so must override and do encoding fixes here.
  def self.sanitize_sql_hash_for_assignment(attrs, table)
    attrs.each do |attr, value|
      attrs[attr] = AsciiConverter.new(string: value.to_s).convert
    end
    super
  end
end
