class WorkQueue::HearingSerializer < ActiveModel::Serializer
  attribute :held_by do
    object.user.full_name
  end

  attribute :held_on do
    object.date
  end

  attribute :type do
    object.type
  end
end
