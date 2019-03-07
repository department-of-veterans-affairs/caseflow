# frozen_string_literal: true

class WorkQueue::LegacyIssueSerializer < ActiveModel::Serializer
  attribute :levels
  attribute(:program) { object.codes[0] }
  attribute(:type) { object.codes[1] }
  attribute(:codes) { object.codes[2..-1] }
  attribute(:disposition) { object.disposition_id }
  attribute :close_date
  attribute :note
  attribute :id
  attribute :vacols_sequence_id
  attribute :labels
  attribute(:readjudication) { false }
  attribute :remand_reasons
end
