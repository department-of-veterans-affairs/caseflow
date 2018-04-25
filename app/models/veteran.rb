# Represents a veteran with values fetched from BGS
#
# TODO: How do we deal with differences between the BGS vet values and the
#       VACOLS vet values (coming from Appeal#veteran_full_name, etc)
class Veteran
  include ActiveModel::Model
  include ActiveModel::Validations
  include AssociatedBgsRecord
  include CachedAttributes

  bgs_attr_accessor :file_number, foreign_key: true

  bgs_attr_accessor :ptcpnt_id, :sex, :first_name, :last_name, :ssn,
                    :address_line1, :address_line2, :address_line3, :city,
                    :state, :country, :zip_code, :military_postal_type_code,
                    :military_post_office_type_code, :service, :date_of_birth

  CHARACTER_OF_SERVICE_CODES = {
    "HON" => "Honorable",
    "UHC" => "Under Honorable Conditions",
    "HVA" => "Honorable for VA Purposes",
    "DVA" => "Dishonorable for VA Purposes",
    "12D" => "Dishonorable - Ch 17 Eligible",
    "12C" => "Dishonorable - Not Ch 17 Eligible",
    "OTH" => "Other Than Honorable",
    "DIS" => "Discharge"
  }.freeze

  COUNTRIES_REQUIRING_ZIP = %w[USA CANADA].freeze

  validates :ssn, :sex, :first_name, :last_name, :city, :address_line1, :country, presence: true
  validates :zip_code, presence: true, if: :country_requires_zip?
  validates :state, presence: true, if: :country_requires_state?

  cache_attribute :cached_serialized_timely_ratings, expires_in: 1.day do
    timely_ratings.map(&:ui_hash)
  end

  def id
    # Aliasing file_number to id for use in cache_attribute key
    file_number
  end

  # TODO: get middle initial from BGS
  def name
    FullName.new(first_name, "", last_name)
  end

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

  def end_products
    @end_products ||= fetch_end_products
  end

  def periods_of_service
    return [] unless service
    service.inject([]) do |result, s|
      result << period_of_service(s) if s[:branch_of_service] && s[:entered_on_duty_date]
      result
    end
  end

  def age
    return unless date_of_birth
    dob = Time.strptime(date_of_birth, "%m/%d/%Y")
    # Age calc copied from https://stackoverflow.com/a/2357790
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def self.bgs
    BGSService.new
  end

  # aliasing because short names suck
  def participant_id
    ptcpnt_id
  end

  def fetch_bgs_record
    result = self.class.bgs.fetch_veteran_info(file_number)

    # If the result is nil, the veteran wasn't found.
    # If the file number is nil, that's another way of saying the veteran wasn't found.
    result && result[:file_number] && result

  rescue BGS::ShareError => error
    # Set the veteran as inaccessible if a sensitivity error is thrown
    raise error unless error.message =~ /Sensitive File/

    @accessible = false
  end

  def accessible?
    self.class.bgs.can_access?(file_number)
  end

  # Postal code might be stored in address line 3 for international addresses
  def zip_code
    @zip_code || (@address_line3 if @address_line3 =~ /(?i)^[a-z0-9][a-z0-9\- ]{0,10}[a-z0-9]$/)
  end

  def timely_ratings
    @timely_ratings ||= Rating.fetch_timely(participant_id: participant_id)
  end

  private

  def fetch_end_products
    self.class.bgs.get_end_products(file_number).map { |ep_hash| EndProduct.from_bgs_hash(ep_hash) }
  end

  def period_of_service(s)
    s[:branch_of_service].strip + " " +
      service_date(s[:entered_on_duty_date]) + " - " +
      service_date(s[:released_active_duty_date]) +
      character_of_service(s)
  end

  def character_of_service(s)
    text = CHARACTER_OF_SERVICE_CODES[s[:char_of_svc_code]]
    text.present? ? ", #{text}" : ""
  end

  def service_date(date)
    return "" unless date
    Date.strptime(date, "%m%d%Y").strftime("%m/%d/%Y")
  rescue ArgumentError
    ""
  end

  def address_type
    return "OVR" if military_address?
    return "INT" if country != "USA"
    "" # Empty string means the address doesn't have a special type
  end

  def vbms_attributes
    self.class.bgs_attributes \
      - [:military_postal_type_code, :military_post_office_type_code, :ptcpnt_id] \
      + [:address_type]
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
