# frozen_string_literal: true

class Relationship
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :participant_id, :first_name, :last_name, :relationship_type, :veteran_file_number, :gender

  class << self
    def from_bgs_hash(veteran, hash)
      new(
        veteran_file_number: veteran.file_number,
        participant_id: hash[:ptcpnt_id],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        relationship_type: hash[:relationship_type],
        gender: hash[:gender]
      )
    end
  end

  def serialize
    Intake::RelationshipSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def default_payee_code
    previous_claim_payee_code || payee_code_by_relationship_type
  end

  private

  def previous_claim_payee_code
    @previous_claim_payee_code ||= latest_end_product.try(:payee_code)
  end

  def payee_code_by_relationship_type
    case relationship_type
    when "Spouse"
      "10"
    when "Child"
      "11"
    when "Parent"
      case gender
      when "M"
        "50"
      when "F"
        "60"
      end
    end
  end

  def latest_end_product
    veteran.find_latest_end_product_by_claimant(self)
  end

  def veteran
    @veteran ||= Veteran.find_by(file_number: veteran_file_number)
  end
end
