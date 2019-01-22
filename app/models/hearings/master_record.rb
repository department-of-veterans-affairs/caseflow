class Hearings::MasterRecord
  include ActiveModel::Model
  include AppealConcern

  attr_accessor :scheduled_for, :request_type, :readable_request_type, :regional_office_key, :master_record, :user_id

  def to_hash
    {
      scheduled_for: scheduled_for,
      request_type: request_type,
      readable_request_type: Hearing::HEARING_TYPES[request_type.to_sym],
      master_record: master_record,
      regional_office_name: regional_office_name
    }
  end
end
