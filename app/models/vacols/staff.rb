# frozen_string_literal: true

class VACOLS::Staff < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.staff"
  self.primary_key = "stafkey"
  scope :load_users_by_css_ids, ->(css_ids) { where(sdomainid: css_ids) }
end
