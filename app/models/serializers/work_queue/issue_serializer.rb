class WorkQueue::IssueSerializer < ActiveModel::Serializer
  attribute :levels
  attribute(:program) { object.codes[0] }
  attribute(:type) { object.codes[1] }
  attribute(:codes) { object.codes[2..-1] }
  attribute :disposition
  attribute :close_date
  attribute :note
  attribute :id
  attribute :vacols_sequence_id
  attribute :labels
  attribute(:readjudication) { false }
  attribute :remand_reasons do
    VACOLS::RemandReason.where(rmdkey: object.id, rmdissseq: object.vacols_sequence_id).map do |reason|
      {
        code: reason.rmdval,
        after_certification: reason.rmddev.eql?("R2")
      }
    end
  end
end
