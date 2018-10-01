# Class used for create / update and do not include computed columns
# since if we do include them ActiveRecord will throw an error.
class Hearings::HearingDayCreateSerializer < ActiveModel::Serializer
  attributes :hearing_pkseq,
             :hearing_type,
             :hearing_date,
             :room,
             :folder_nr,
             :board_member,
             :mduser,
             :mdtime

  def attributes(attributes)
    hash = super
    Hearings::HearingDaySerializer.resolved_attributes(hash)
  end
end
