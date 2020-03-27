# frozen_string_literal: true

# Represents a veteran with values fetched from BGS
#
# TODO: How do we deal with differences between the BGS vet values and the
#       VACOLS vet values (coming from Appeal#veteran_full_name, etc)
class Veteran < CaseflowRecord
  include AssociatedBgsRecord

  has_many :available_hearing_locations,
           foreign_key: :veteran_file_number,
           primary_key: :file_number, class_name: "AvailableHearingLocations"

  bgs_attr_accessor :ptcpnt_id, :sex, :address_line1, :address_line2,
                    :address_line3, :city, :state, :country, :zip_code,
                    :military_postal_type_code, :military_post_office_type_code,
                    :service, :date_of_birth, :date_of_death, :email_address

  validates :first_name, :last_name, presence: true, on: :bgs
  validates :address_line1, :address_line2, :address_line3, length: { maximum: 20 }, on: :bgs
  validate :validate_address_line, on: :bgs
  validate :validate_city, on: :bgs
  validate :validate_birth_date, on: :bgs

  with_options if: :alive? do
    validates :address_line1, :country, presence: true, on: :bgs
    validates :zip_code, presence: true, if: :country_requires_zip?, on: :bgs
    validates :state, presence: true, if: :state_is_required?, on: :bgs
    validates :city, presence: true, unless: :military_address?, on: :bgs
  end

  delegate :full_address, to: :address

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

  # Germany and Australia should be temporary additions until VBMS bug is fixed
  COUNTRIES_REQUIRING_ZIP = %w[USA CANADA].freeze

  # C&P Live = '1', C&P Death = '2'
  BENEFIT_TYPE_CODE_LIVE = "1"
  BENEFIT_TYPE_CODE_DEATH = "2"

  # key is local attribute name; value is corresponding bgs attribute name
  CACHED_BGS_ATTRIBUTES = {
    first_name: :first_name,
    last_name: :last_name,
    middle_name: :middle_name,
    name_suffix: :name_suffix,
    ssn: :ssn,
    participant_id: :ptcpnt_id
  }.freeze

  # TODO: get middle initial from BGS
  def name
    FullName.new(first_name, "", last_name)
  end

  def person
    @person ||= Person.find_or_create_by(participant_id: participant_id)
  end

  def country_requires_zip?
    COUNTRIES_REQUIRING_ZIP.include?(country&.upcase)
  end

  def state_is_required?
    !military_address? && country_requires_state?
  end

  def country_requires_state?
    country && country.casecmp("USA") == 0
  end

  # Convert to hash used in AppealRepository.establish_claim!
  def to_vbms_hash
    military_address? ? military_address_vbms_hash : base_vbms_hash
  end

  def find_latest_end_product_by_claimant(claimant)
    end_products.select do |ep|
      ep.claimant_first_name == claimant.first_name && ep.claimant_last_name == claimant.last_name
    end.max_by(&:claim_date)
  end

  def end_products
    @end_products ||= fetch_end_products
  end

  def periods_of_service
    return [] unless service

    service.inject([]) do |result, service_attributes|
      if service_attributes[:branch_of_service] && service_attributes[:entered_on_duty_date]
        result << period_of_service(service_attributes)
      end
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

  def benefit_type_code
    @benefit_type_code ||= deceased? ? BENEFIT_TYPE_CODE_DEATH : BENEFIT_TYPE_CODE_LIVE
  end

  def fetch_bgs_record
    result = bgs.fetch_veteran_info(file_number)

    # If the result is nil, the veteran wasn't found.
    # If the participant id is nil, that's another way of saying the veteran wasn't found.
    return result if result && result[:ptcpnt_id]
  rescue BGS::ShareError => error
    handle_bgs_share_error(error)
  end

  def accessible?
    bgs.can_access?(file_number)
  end

  def access_error
    @access_error ||= nil if bgs_record.is_a?(Hash)
  rescue BGS::ShareError => error
    error.message
  end

  # When two Veteran records get merged for data clean up, it can lead to multiple active phone numbers
  # This causes an error fetching the BGS record and needs to be fixed in SHARE
  def multiple_phone_numbers?
    if !!access_error&.include?("NonUniqueResultException")
      bgs.bust_can_access_cache(RequestStore[:current_user], file_number)

      true
    else
      false
    end
  end

  def relationships
    @relationships ||= fetch_relationships
  end

  def relationship_with_participant_id(match_id = nil)
    relationships&.find do |relationship|
      relationship.participant_id == match_id
    end
  end

  def incident_flash?
    bgs_record.is_a?(Hash) && bgs_record[:block_cadd_ind] == "S"
  end

  # Postal code might be stored in address line 3 for international addresses
  def zip_code
    @zip_code || (@address_line3 if (@address_line3 || "").match?(/(?i)^[a-z0-9][a-z0-9\- ]{0,10}[a-z0-9]$/))
  end
  alias zip zip_code
  alias address_line_1 address_line1
  alias address_line_2 address_line2
  alias address_line_3 address_line3
  alias gender sex

  def validate_address_line
    [:address_line1, :address_line2, :address_line3].each do |address|
      address_line = instance_variable_get("@#{address}")
      next if address_line.blank?

      # This regex validation is used in VBMS to validate address of veteran
      unless address_line.match?(/^(?!.*\s\s)[a-zA-Z0-9+#@%&()_:',.\-\/\s]*$/)
        errors.add(address.to_sym, "invalid_characters")
      end
    end
  end

  def validate_birth_date
    # return if date_of_birth.blank?
     binding.pry
     errors.add(:date_of_birth, "missing_leading_zero") unless date_of_birth.match?(/^(0[1-9]|1[012])\/(0[1-9]|[12][0-9]|3[01])\/(19|20)\d\d/)
  end

  def validate_city
    return if city.blank?

    # This regex validation is used in VBMS to vakidate address of veteran
    errors.add(:city, "invalid_characters") unless city.match?(/^[ a-zA-Z0-9`\\'~=+\[\]{}#?\^*<>!@$%&()\-_|;:",.\/]*$/)
  end

  def timely_ratings(from_date:)
    @timely_ratings ||= Rating.fetch_timely(participant_id: participant_id, from_date: from_date)
  end

  def ratings
    @ratings ||= Rating.fetch_all(participant_id)
  end

  def decision_issues
    DecisionIssue.where(participant_id: participant_id)
  end

  def participant_id
    super || ptcpnt_id
  end

  def ssn
    super || (bgs_record.is_a?(Hash) ? bgs_record[:ssn] : nil)
  end

  def address
    @address ||= Address.new(
      address_line_1: address_line1,
      address_line_2: address_line2,
      address_line_3: address_line3,
      city: city,
      state: state,
      country: country,
      zip: zip_code
    )
  end

  def validate_address
    response = VADotGovService.validate_address(address)

    return response.data if response.success?

    raise response.error # rubocop:disable Style/SignalException
  end

  def stale?
    (first_name.nil? || last_name.nil? || self[:ssn].nil? || self[:participant_id].nil? ||
      email_address.nil?)
  end

  def stale_attributes?
    return false unless accessible? && bgs_record.is_a?(Hash)

    is_stale = stale?
    is_stale ||= CACHED_BGS_ATTRIBUTES.any? { |local_attr, bgs_attr| self[local_attr] != bgs_record[bgs_attr] }
    is_stale
  end

  def update_cached_attributes!
    CACHED_BGS_ATTRIBUTES.each do |local_attr, bgs_attr|
      self[local_attr] = bgs_record[bgs_attr]
    end
    save!
  end

  class << self
    def find_or_create_by_file_number(file_number, sync_name: false)
      find_by_file_number_and_sync(file_number, sync_name: sync_name) || create_by_file_number(file_number)
    end

    def find_by_ssn(ssn, sync_name: false)
      found_locally = find_by(ssn: ssn)
      if found_locally && sync_name && found_locally.stale_attributes?
        found_locally.update_cached_attributes!
      end
      return found_locally if found_locally

      file_number = bgs.fetch_file_number_by_ssn(ssn)
      return unless file_number

      find_by_file_number_and_sync(file_number, sync_name: sync_name)
    end

    def find_by_file_number_or_ssn(file_number_or_ssn, sync_name: false)
      if file_number_or_ssn.to_s.length == 9
        find_by_ssn(file_number_or_ssn, sync_name: sync_name) ||
          find_by_file_number_and_sync(file_number_or_ssn, sync_name: sync_name)
      else
        find_by_file_number_and_sync(file_number_or_ssn, sync_name: sync_name)
      end
    end

    def find_or_create_by_file_number_or_ssn(file_number_or_ssn, sync_name: false)
      if file_number_or_ssn.to_s.length == 9
        find_by_file_number_and_sync(file_number_or_ssn, sync_name: sync_name) ||
          find_or_create_by_ssn(file_number_or_ssn, sync_name: sync_name) ||
          find_or_create_by_file_number(file_number_or_ssn, sync_name: sync_name)
      else
        find_or_create_by_file_number(file_number_or_ssn, sync_name: sync_name)
      end
    end

    private

    def find_or_create_by_ssn(ssn, sync_name: false)
      found_locally = find_by(ssn: ssn)
      if found_locally && sync_name && found_locally.stale_attributes?
        found_locally.update_cached_attributes!
      end
      return found_locally if found_locally

      file_number = bgs.fetch_file_number_by_ssn(ssn)
      return unless file_number

      find_or_create_by_file_number(file_number, sync_name: sync_name)
    end

    def find_by_file_number_and_sync(file_number, sync_name: false)
      veteran = find_by(file_number: file_number)
      return nil unless veteran

      # Check to see if veteran is accessible to make sure bgs_record is
      # a hash and not :not_found. Also if it's not found, bgs_record returns
      # a symbol that will blow up, so check if bgs_record is a hash first.
      if sync_name
        Rails.logger.warn(%(find_by_file_number_and_sync veteran:#{file_number} accessible:#{veteran.accessible?}))

        if veteran.cached_attributes_updatable?
          veteran.update_cached_attributes!
        end
      end
      veteran
    end

    def create_by_file_number(file_number)
      fail "file_number must not be nil" if file_number.blank?

      veteran = Veteran.new(file_number: file_number)

      unless veteran.found?
        return nil
      end

      return veteran unless veteran.accessible?

      before_create_veteran_by_file_number # Used to simulate race conditions
      veteran.tap(&:update_cached_attributes!)
    rescue ActiveRecord::RecordNotUnique
      find_by(file_number: file_number)
    end

    def before_create_veteran_by_file_number
      # noop - used to simulate race conditions
    end
  end

  def cached_attributes_updatable?
    accessible? && bgs_record.is_a?(Hash) && stale_attributes?
  end

  def deceased?
    !date_of_death.nil?
  end

  def alive?
    !deceased?
  end

  def unload_bgs_record
    @bgs_record_loaded = false
    @bgs_record = nil
  end

  private

  def handle_bgs_share_error(error)
    @access_error = error.message

    # Now that we are always checking find_flashes for access control before we fetch the
    # veteran, we should never see this error. Reporting it to sentry if it happens
    unless error.message.match?(/Sensitive File/)
      Raven.capture_exception(error)
      fail error
    end

    # Set the veteran as inaccessible if a sensitivity error is thrown
    @accessible = false
  end

  def fetch_end_products
    bgs_end_products = bgs.get_end_products(file_number)

    # Check that we are not getting this back from BGS:
    # [{:number_of_records=>"0", :return_code=>"SHAR 9999", :return_message=>"Records found"}]
    return [] if bgs_end_products.first && bgs_end_products.first[:number_of_records] == "0"

    bgs_end_products.map { |ep_hash| EndProduct.from_bgs_hash(ep_hash) }
  end

  def fetch_relationships
    relationship_hashes = Array.wrap(bgs.find_all_relationships(participant_id: participant_id))
    relationship_hashes.map do |relationship_hash|
      Relationship.from_bgs_hash(self, relationship_hash)
    end
  end

  def period_of_service(service_attributes)
    service_attributes[:branch_of_service].strip + " " +
      service_date(service_attributes[:entered_on_duty_date]) + " - " +
      service_date(service_attributes[:released_active_duty_date]) +
      character_of_service(service_attributes)
  end

  def character_of_service(service_attributes)
    text = CHARACTER_OF_SERVICE_CODES[service_attributes[:char_of_svc_code]]
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
      + [:file_number, :address_type, :first_name, :last_name, :name_suffix, :ssn]
  end

  def military_address?
    military_postal_type_code.present?
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
