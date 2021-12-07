# frozen_string_literal: true

class ClaimsFolderSearch < CaseflowRecord
  belongs_to :appeal, polymorphic: true
  belongs_to :user
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: claims_folder_searches
#
#  id          :integer          not null, primary key
#  appeal_type :string           not null, indexed => [appeal_id]
#  query       :string
#  created_at  :datetime
#  updated_at  :datetime         indexed
#  appeal_id   :integer          indexed => [appeal_type]
#  user_id     :integer          indexed
#
# Foreign Keys
#
#  fk_rails_fc7d5f13d2  (user_id => users.id)
#
