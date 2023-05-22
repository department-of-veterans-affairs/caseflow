# frozen_string_literal: true

class WorkQueue::LegacyIssueSerializer
  include FastJsonapi::ObjectSerializer

  attribute :levels
  attribute(:program) { |object| object.codes[0] }
  attribute(:type) { |object| object.codes[1] }
  attribute :codes do |object|
    object.codes[2..-1]
  end
  attribute :disposition, &:disposition_id
  attribute :close_date
  attribute :note
  attribute :vacols_sequence_id
  attribute :labels
  attribute(:readjudication) { false }
  attribute :remand_reasons
  attribute :legacy_appeal_vacols_mst
  attribute :legacy_appeal_vacols_pact
end
