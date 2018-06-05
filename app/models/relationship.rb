class Relationship
  class << self
    def from_bgs_hash(hash)
      new(
        participant_id: hash[:ptcpnt_id],
        relationship_type: hash[:relationship_type]
      )
    end
  end
end
