# frozen_string_literal: true

class AppealView < CaseflowRecord
  belongs_to :appeal, polymorphic: true
  belongs_to :user
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: appeal_views
#
#  id             :integer          not null, primary key
#  appeal_type    :string           not null, indexed => [appeal_id, user_id]
#  last_viewed_at :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  appeal_id      :integer          not null, indexed => [appeal_type, user_id]
#  user_id        :integer          not null, indexed => [appeal_type, appeal_id]
#
# Foreign Keys
#
#  fk_rails_0eb8e688f0  (user_id => users.id)
#
