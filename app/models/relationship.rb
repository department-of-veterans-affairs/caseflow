class Relationship
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :participant_id, :first_name, :last_name, :relationship_type

  class << self
    def from_bgs_hash(hash)
      hashArray = Array.wrap(hash)
      new(
        participant_id: hashArray[:ptcpnt_id],
        first_name: hashArray[:first_name],
        last_name: hashArray[:last_name],
        relationship_type: hashArray[:relationship_type]
      )
    end
  end
end
