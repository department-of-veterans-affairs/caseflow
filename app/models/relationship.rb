class Relationship
  class << self
    def from_bgs_hash(hash)
      new(
        participant_id: hash[:ptcpnt_id],
        first_name: hash[:first_name],
        last_name: hash[:last_name],
        relationship_type: hash[:relationship_type]
      )
    end
  end
end
