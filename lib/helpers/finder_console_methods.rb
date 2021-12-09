# frozen_string_literal: true

##
# Provides a set of methods to find DB records
# See https://github.com/department-of-veterans-affairs/caseflow/wiki/Active-Record-Queries-Resource for more queries

# :reek:FeatureEnvy
# :reek:UtilityFunction
module FinderConsoleMethods
  UUID_REGEX ||= /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.freeze
  def uuid?(uuid)
    UUID_REGEX.match?(uuid.to_s.downcase)
  end

  # Convenience method to find an AMA Appeal or LegacyAppeal
  # The `identifier` argument is the UUID or VACOLS_ID in the Case Detail URL, or a docket_number
  # Usage examples:
  #   _appeal "1c11a1ae-43bd-449b-9416-7ccb9cb06c11"
  #   _appeal 1234567
  #   amas, legacies = _appeal "211025-193327"
  def _appeal(identifier)
    appeal = uuid?(identifier) ? Appeal.find_by(uuid: identifier) : LegacyAppeal.find_by(vacols_id: identifier)
    return appeal if appeal

    docket_number = identifier
    vids = VACOLS::Case.joins(:folder).where("folder.tinum": docket_number).map(&:id)
    [Appeal.where(stream_docket_number: docket_number), LegacyAppeal.where(vacols_id: vids)]
  end

  # The `identifier` argument can be a file_number or SSN.
  # Usage examples:
  #   vet, appeals, legacies, crs = _veteran 123456789
  #   vet = _veteran(123456789).first
  def _veteran(identifier)
    vet = Veteran.find_by_file_number_or_ssn(identifier)
    return nil unless vet

    appeals = AppealFinder.find_appeals_with_file_numbers(vet.file_number)
    legacies = LegacyAppeal.fetch_appeals_by_file_number(vet.file_number)
    crs = ClaimReview.find_all_visible_by_file_number(vet.file_number)

    [vet, appeals, legacies, crs]
  end

  # The case-insensitive `identifier` argument can be a record id, CSS_ID, VACOLS slogid, or part of a full name.
  # Usage examples:
  #   pp _user 3
  #   pp _user "BvaAAbshire"
  #   pp _user 'ABS'
  # rubocop:disable Metrics/CyclomaticComplexity
  def _user(identifier)
    user = User.find(identifier) if identifier.is_a? Numeric
    return user if user

    user = User.find_by_css_id(identifier.upcase) if identifier.is_a? String
    return user if user

    staff = VACOLS::Staff.find_by(slogid: identifier.upcase)
    return User.find_by_css_id(staff.sdomainid) if staff

    users = User.where("full_name ILIKE ?", "%#{identifier}%")
    return users.first if users.count == 1

    puts "Found #{users.count} users with full_name like %#{identifier.upcase}%: #{users.pluck(:css_id, :full_name)}"
    users
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # The case-insensitive `identifier` argument can be a User, CSS_ID (sdomainid), VACOLS slogid, or partial last name.
  # Usage examples:
  #   pp _staff User.last
  #   pp _staff "Abshir"
  def _staff(identifier)
    return VACOLS::Staff.find_by(sdomainid: identifier.css_id) if identifier.is_a? User

    staff = VACOLS::Staff.find_by(slogid: identifier.upcase)
    return staff if staff

    staff = VACOLS::Staff.find_by(sdomainid: identifier.upcase)
    return staff if staff

    staffs = VACOLS::Staff.where("UPPER(snamel) LIKE ?", "%#{identifier.upcase}%")
    return staffs.first if staffs.count == 1

    puts "Found #{staffs.count} staffs with last name like %#{identifier}%: " \
         "#{staffs.pluck(:sdomainid, :slogid, :snamef, :snamel)}"
    staffs
  end
end
