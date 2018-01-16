class WorkQueue::IssueSerializer < ActiveModel::Serializer
  attribute :close_date
  attribute :codes
  attribute :disposition
  attribute :id
  attribute :labels
  attribute :note
  attribute :vacols_sequence_id
end
