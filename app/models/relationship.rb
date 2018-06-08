class Relationship
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :participant_id, :first_name, :last_name, :relationship_type

  class << self
    def from_bgs_hash(_hash)
      new(
        participant_id: hash_array[:ptcpnt_id],
        first_name: hash_array[:first_name],
        last_name: hash_array[:last_name],
        relationship_type: hash_array[:relationship_type]
      )
    end
  end
end
