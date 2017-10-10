class Intake < ActiveRecord::Base
  belongs_to :user
  belongs_to :detail, polymorphic: true

  attr_reader :error_code

  def start!
    return false unless valid_to_start?

    # TODO: Fill this out with everything that happens on start
    true
  end

  def valid_to_start?
    if !file_number_valid?
      @error_code = :invalid_file_number

    elsif !veteran.found?
      @error_code = :veteran_not_found

    elsif !veteran.accessible?
      @error_code = :veteran_not_accessible

    else
      validate_detail_on_start

    end

    !error_code
  end

  private

  def veteran
    @veteran ||= Veteran.new(file_number: veteran_file_number).load_bgs_record!
  end

  def file_number_valid?
    veteran_file_number =~ /[0-9]{8,}/
  end

  # Optionally implement this methods in subclass
  def validate_detail_on_start
    true
  end
end
