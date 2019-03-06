# frozen_string_literal: true

class AppealStreamSnapshot < ApplicationRecord
  self.table_name = "hearing_appeal_stream_snapshots"

  belongs_to :hearing, class_name: "LegacyHearing"
  belongs_to :appeal, class_name: "LegacyAppeal"
end
