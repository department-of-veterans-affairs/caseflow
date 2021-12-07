# frozen_string_literal: true

class GlobalAdminLogin < CaseflowRecord
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: global_admin_logins
#
#  id                :integer          not null, primary key
#  created_at        :datetime
#  updated_at        :datetime         indexed
#  admin_css_id      :string
#  target_css_id     :string
#  target_station_id :string
#
