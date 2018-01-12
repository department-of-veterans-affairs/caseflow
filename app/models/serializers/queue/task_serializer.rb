class QueueSerializers::TaskSerializer < ActiveModel::Serializer
  attribute :assigned_on
  attribute :due_on
  attribute :docket_name
  attribute :docket_date
  attribute :appeal_id
  attribute :user_id


  attribute :appeal do
    ActiveModelSerializers::SerializableResource.new(
      object.appeal,
      each_serializer: ::V1::AppealSerializer,
      include: "hearings"
    ).as_json
  end
end
