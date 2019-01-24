class Relationship
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :participant_id, :first_name, :last_name, :relationship_type, :veteran_file_number

  class << self
    def from_bgs_hash(veteran, hash)
      new(
        veteran_file_number: veteran.file_number,
        participant_id: hash[:ptcpnt_id],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        relationship_type: hash[:relationship_type]
      )
    end
  end

  def ui_hash
    {
      participant_id: participant_id,
      first_name: first_name,
      last_name: last_name,
      relationship_type: relationship_type,
      default_payee_code: default_payee_code
    }
  end

  private

  def default_payee_code
    @default_payee_code ||= end_products.max_by(&:claim_date).try(:payee_code)
  end

  def end_products
    veteran.end_products.select { |ep| ep.claimant_first_name == first_name && ep.claimant_last_name == last_name }
  end

  def veteran
    @veteran ||= Veteran.find_by(file_number: veteran_file_number)
  end
end
