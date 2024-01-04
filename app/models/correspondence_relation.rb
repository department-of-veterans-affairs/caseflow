# frozen_string_literal: true

class CorrespondenceRelation < ApplicationRecord
  belongs_to :correspondence
  belongs_to :related_correspondence, class_name: "Correspondence"

  # Makes the relationship bi-directional - both Correspondences are aware of the relationship
  after_create :create_inverse, unless: :inverse_exists?
  after_destroy :destroy_inverses, if: :inverse_exists?

  validates_presence_of :correspondence_id
  validates_presence_of :related_correspondence_id
  validates_numericality_of :correspondence_id
  validates_numericality_of :related_correspondence_id

  def create_inverse
    self.class.create(inverse_match_options)
  end

  def destroy_inverses
    inverses.destroy_all
  end

  def inverse_exists?
    self.class.exists?(inverse_match_options)
  end

  def inverses
    self.class.where(inverse_match_options)
  end

  def inverse_match_options
    { related_correspondence_id: correspondence_id, correspondence_id: related_correspondence_id }
  end
end
