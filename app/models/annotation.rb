class Annotation < ActiveRecord::Base
  def to_hash
    serializable_hash(
      methods: [:document_id, :comment, :location_x, :location_y, :page]
    )
  end
end