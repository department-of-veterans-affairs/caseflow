class VACOLS::Decass < VACOLS::Record
  self.table_name = "vacols.decass"
  self.primary_key = "defolder"

  class DecassError < StandardError; end

  has_one :case, foreign_key: :bfkey

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
end
