# frozen_string_literal: true

class ApiView < CaseflowRecord
  belongs_to :api_key
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: api_views
#
#  id         :integer          not null, primary key
#  source     :string
#  created_at :datetime
#  updated_at :datetime
#  api_key_id :integer
#  vbms_id    :string
#
# Foreign Keys
#
#  fk_rails_23c12f1a27  (api_key_id => api_keys.id)
#
