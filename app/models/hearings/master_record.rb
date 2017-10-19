class Hearings::MasterRecord
  include ActiveModel::Model
  include RegionalOfficeConcern
  include HearingConcern

  attr_accessor :date, :type, :regional_office_key, :master_record, :user_id

  def to_hash
    {
      date: date,
      request_type: request_type,
      master_record: master_record,
      regional_office_name: regional_office_name
    }
  end
end
