# frozen_string_literal: true

class HearingView < CaseflowRecord
  belongs_to :hearing, polymorphic: true
  belongs_to :user
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: hearing_views
#
#  id           :integer          not null, primary key
#  hearing_type :string           indexed => [hearing_id, user_id]
#  created_at   :datetime
#  updated_at   :datetime
#  hearing_id   :integer          not null, indexed => [user_id, hearing_type]
#  user_id      :integer          not null, indexed => [hearing_id, hearing_type]
#
# Foreign Keys
#
#  fk_rails_4998bbb1b0  (user_id => users.id)
#
