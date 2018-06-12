class Hearings::HearingDaySerializer < ActiveModel::Serializer
  attribute :hearing_pkseq
  attribute :hearing_type
  attribute :hearing_date
  attribute :room
  attribute :repname
  attribute :folder_nr
  attribute :board_member
  attribute :mduser
  attribute :mdtime
  attribute :canceldate
end