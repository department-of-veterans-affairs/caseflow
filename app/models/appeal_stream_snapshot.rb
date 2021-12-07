# frozen_string_literal: true

class AppealStreamSnapshot < CaseflowRecord
  self.table_name = "hearing_appeal_stream_snapshots"

  belongs_to :hearing, class_name: "LegacyHearing"
  belongs_to :appeal, class_name: "LegacyAppeal"
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: hearing_appeal_stream_snapshots
#
#  created_at :datetime         not null
#  updated_at :datetime         indexed
#  appeal_id  :integer          indexed => [hearing_id]
#  hearing_id :integer          indexed => [appeal_id]
#
# Foreign Keys
#
#  fk_rails_10dc890266  (appeal_id => legacy_appeals.id)
#  fk_rails_daabbdc768  (hearing_id => legacy_hearings.id)
#
