# frozen_string_literal: true

class NodDateUpdate < CaseflowRecord
  belongs_to :appeal
  belongs_to :user

  validates :appeal, :user, :old_date, :new_date, :change_reason, presence: true

  delegate :request_issues, to: :appeal

  enum change_reason: {
    entry_error: "entry_error",
    new_info: "new_info"
  }
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: nod_date_updates
#
#  id            :bigint           not null, primary key
#  change_reason :string           not null
#  new_date      :date             not null
#  old_date      :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  appeal_id     :bigint           not null, indexed
#  user_id       :bigint           not null, indexed
#
# Foreign Keys
#
#  fk_rails_2cfba7b6f9  (user_id => users.id)
#  fk_rails_9868c033a2  (appeal_id => appeals.id)
#
