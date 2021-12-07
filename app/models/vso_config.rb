# frozen_string_literal: true

class VsoConfig < CaseflowRecord
  belongs_to :organization
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: vso_configs
#
#  id              :bigint           not null, primary key
#  ihp_dockets     :string           is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null, indexed
#  organization_id :integer          indexed
#
# Foreign Keys
#
#  fk_rails_8f5b956e5a  (organization_id => organizations.id)
#
