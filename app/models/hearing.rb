class Hearing < ActiveRecord::Base
  # belongs_to :appeal
  # belongs_to :user

  attr_accessor :date, :type, :regional_office_key, :vacols_record

  # This key maps to the `FOLDER_NR` column in HEARSCHED
  # and the `BFKEY` column in BRIEFF
  attr_accessor :vacols_case_id

  # This key maps to the `BFKEY` column in BRIEFF
  attr_accessor :vacols_user_id

  def attributes
    {
      date: date,
      type: type
    }
  end

  def self.load_from_vacols(vacols_hearing, vacols_user_id)
    find_or_create_by(vacols_id: vacols_hearing.hearing_pkseq).tap do |hearing|
      hearing.user_id = User.find_by_vacols_id(vacols_user_id).try(:id)
    end
  end
end
