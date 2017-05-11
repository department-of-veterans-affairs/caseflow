class Hearing
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_accessor :date, :type, :regional_office_key

  # This key maps to the `FOLDER_NR` column in HEARSCHED
  # and the `BFKEY` column in BRIEFF
  attr_accessor :vacols_case_id

  # This key maps to the `BFKEY` column in BRIEFF
  attr_accessor :vacols_user_id

  def attributes
    {
      date: date,
      type: type,
    }
  end
end
