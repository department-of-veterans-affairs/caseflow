# Class used for queries where computed column judge_name is included.
class Hearings::HearingDaySerializer < ActiveModel::Serializer
  attributes :hearing_pkseq,
             :hearing_type,
             :hearing_date,
             :room,
             :folder_nr,
             :board_member,
             :judge_name,
             :mduser,
             :mdtime

  def attributes(attributes)
    hash = super
    self.class.resolved_attributes(hash)
  end

  def self.resolved_attributes(hash_to_map)
    hearing_hash =
      hash_to_map.each_with_object({}) { |(k, v), result| result[HearingDayMapper::COLUMN_NAME_REVERSE_MAP[k]] = v }
    values_hash = hearing_hash.each_with_object({}) do |(k, v), result|
      if k.to_s == "room_info"
        result[k] = HearingDayMapper.label_for_room(v)
      elsif k.to_s == "regional_office" && !v.nil?
        ro = v[6, v.length]
        result[k] = HearingDayMapper.city_for_regional_office(ro)
      elsif k.to_s == "hearing_type"
        result[k] = HearingDayMapper.label_for_type(v)
      else
        result[k] = v
      end
    end
    values_hash
  end
end
