# frozen_string_literal: true

class VACOLS::Decass < VACOLS::Record
  # :nocov:
  self.table_name = "decass"
  self.primary_key = "defolder"

  attribute :deatcom, :ascii_string, limit: 350
  attribute :debmcom, :ascii_string, limit: 600

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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: decass
#
#  de1touch    :string(1)
#  deadtim     :date
#  deadusr     :string(12)
#  dearem      :string(1)
#  deassign    :date
#  deatcom     :string(350)
#  deatty      :string(16)       indexed
#  debmcom     :string(600)
#  decomp      :date
#  dedeadline  :date
#  dedocid     :string(30)
#  defcr       :decimal(5, 2)
#  defdiff     :string(1)
#  defolder    :string(12)       primary key, indexed
#  dehours     :decimal(5, 2)
#  deicr       :decimal(5, 2)
#  delock      :string(1)
#  demdtim     :date
#  demdusr     :string(12)
#  dememid     :string(16)
#  deoq        :string(1)
#  depdiff     :string(1)
#  deprod      :string(3)
#  deprogrev   :date
#  deqr1       :string(1)
#  deqr10      :string(1)
#  deqr11      :string(1)
#  deqr2       :string(1)
#  deqr3       :string(1)
#  deqr4       :string(1)
#  deqr5       :string(1)
#  deqr6       :string(1)
#  deqr7       :string(1)
#  deqr8       :string(1)
#  deqr9       :string(1)
#  dereceive   :date
#  derecommend :string(1)
#  deteam      :string(3)
#  detrem      :string(1)
#
