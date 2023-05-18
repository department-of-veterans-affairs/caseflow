# frozen_string_literal: true

class VACOLS::Decass < VACOLS::Record
  # :nocov:
  self.table_name = "decass"
  self.primary_key = "defolder"

  attribute :deatcom, :ascii_string, limit: 350
  attribute :debmcom, :ascii_string, limit: 600
  attribute :deassign, :datetime
  attribute :dereceive, :datetime

  validates :defolder, :deatty, :deteam, :deadusr, :deadtim, presence: true, on: :create

  class DecassError < StandardError; end

  has_one :case, foreign_key: :bfkey

  delegate :update_vacols_location!, to: :case

  def omo_request?
    Constants::DECASS_WORK_PRODUCT_TYPES["OMO_REQUEST"].include? deprod
  end

  def draft_decision?
    Constants::DECASS_WORK_PRODUCT_TYPES["DRAFT_DECISION"].include? deprod
  end

  def update(*)
    update_error_message
  end

  def update!(*)
    update_error_message
  end

  private

  def update_error_message
    fail DecassError, "Since the primary key is not unique, `update` will update all results
      with the same `defolder`. Instead use QueueRepository.update_decass_record
      that uses `defolder` and `deassign` to safely update one record"
  end
  # :nocov:
end
