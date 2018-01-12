class QueueSerializers::AppealSerializer < ActiveModel::Serializer

  has_many :scheduled_hearings, serializer: ::QueueSerializers::HearingSerializer

  attribute :veteran_full_name
  attribute :vbms_id
  attribute :vacols_id
  attribute :type
  attribute :aod
  attribute :regional_office
  attribute :issues
end
