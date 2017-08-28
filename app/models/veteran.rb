# Represents a veteran with values fetched from BGS
#
# TODO: How do we deal with differences between the BGS vet values and the
#       VACOLS vet values (coming from Appeal#veteran_full_name, etc)
class Veteran
  include ActiveModel::Model
  include ActiveModel::Validations

  BGS_ATTRIBUTES = %i(
    file_number sex first_name last_name ssn address_line1 address_line2
    address_line3 city state country zip_code military_postal_type_code
    military_post_office_type_code
  ).freeze

  attr_accessor(*BGS_ATTRIBUTES)
  attr_accessor :date_of_birth

  COUNTRIES_REQUIRING_ZIP = %w(USA CANADA).freeze

  validates :ssn, :first_name, :last_name, :city, :address_line1, :country, presence: true
  validates :zip_code, presence: true, if: "country_requires_zip?"
  validates :state, presence: true, if: "country_requires_state?"

  def country_requires_zip?
    COUNTRIES_REQUIRING_ZIP.include?(country)
  end

  def country_requires_state?
    country == "USA"
  end

  # Convert to hash used in AppealRepository.establish_claim!
  def to_vbms_hash
    military_address? ? military_address_vbms_hash : base_vbms_hash
  end

  def load_bgs_record!
    BGS_ATTRIBUTES.each do |bgs_attribute|
      instance_variable_set(
        "@#{bgs_attribute}".to_sym,
        bgs_record[bgs_attribute]
      )
    end

    self
  end

  def self.bgs
    BGSService.new
  end

  def age
    return unless date_of_birth
    dob = date_of_birth
    # Age calc copied from https://stackoverflow.com/a/2357790
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  private

  def address_type
    return "OVR" if military_address?
    return "INT" if country != "USA"
    "" # Empty string means the address doesn't have a special type
  end

  def bgs_record
    @bgs_record ||= fetch_bgs_record
  end

  def fetch_bgs_record
    self.class.bgs.fetch_veteran_info(file_number)
  end

  def vbms_attributes
    BGS_ATTRIBUTES - [:military_postal_type_code, :military_post_office_type_code] + [:address_type]
  end

  def military_address?
    !military_postal_type_code.blank?
  end

  def base_vbms_hash
    vbms_attributes.each_with_object({}) do |attribute, vbms_hash|
      vbms_hash[attribute] = send(attribute)
    end
  end

  def military_address_vbms_hash
    base_vbms_hash.merge(
      state: military_postal_type_code,
      city: military_post_office_type_code
    )
  end
end
