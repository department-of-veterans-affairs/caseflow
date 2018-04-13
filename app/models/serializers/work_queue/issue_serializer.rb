class WorkQueue::IssueSerializer < ActiveModel::Serializer
  attribute :levels
  attribute(:program) { object.codes[0] }
  attribute(:type) { object.codes[1] }
  attribute :disposition
  attribute :close_date
  attribute :note
  attribute :id
  attribute :vacols_sequence_id
  attribute :labels
  attribute(:codes) { object.codes[2..-1] }
  attribute :description
end
