class Hearings::HearingDaySerializer < ActiveModel::Serializer
  attributes :hearing_pkseq, :hearing_type, :hearing_date, :room, :folder_nr, :board_member, :mduser, :mdtime

  def attributes(attributes)
    hash = super
    hearing_hash =
      hash.each_with_object({}) { |(k, v), result| result[HearingDayMapper::COLUMN_NAME_REVERSE_MAP[k]] = v }
    hearing_hash
  end
end
