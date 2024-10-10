# frozen_string_literal: true

class DuplicateVeteranFixer
  attr_reader :duplicate_relations_count_log, :duplicate_relations,
              :correct_relations_count_log, :correct_relations,
              :updated_relations_count_log, :remaining_relations_count_log

  # :reek:UncommunicativeVariableName
  # :reek:Too ManyInstanceVariables
  def initialize(duplicate_veteran_file_number)
    @duplicate_veteran_file_number = duplicate_veteran_file_number
    @correct_veteran = nil
    @duplicate_relations_count_log = ["Duplicate Veteran Relations:\n "]
    @correct_relations_count_log = ["Correct Veteran Relations:\n "]
    @updated_relations_count_log = ["Updated relations count log:\n "]
    @remaining_relations_count_log = ["Remaining Duplicate Relations:\n "]
    @failure_log = []
    @duplicate_relations = {} # as: { relations: rels, count: rels.length } - uses old file number
    @correct_relations = {} # as: { relations: rels, count: rels.length } - uses bgs file number and vbms_id
  end

  RELATIONS = {
    as: { class: Appeal, name: " Appeals" },
    las: { class: LegacyAppeal, name: " LegacyAppeals" },
    ahls: { class: AvailableHearingLocations, name: " Available Hearing Locations" },
    bpoas: { class: BgsPowerOfAttorney, name: " BgsPowerOfAttorneys" },
    ds: { class: Document, name: " Documents" },
    epes: { class: EndProductEstablishment, name: " EndProductEstablishment" },
    f8s: { class: Form8, name: " Form8" },
    hlrs: { class: HigherLevelReview, name: " HigherLevelReview" },
    is_fn: { class: Intake, name: " Intakes related by file number" }, # by file number
    is_vi: { class: Intake, name: " Intakes related by veteran id" }, # by veteran id
    res: { class: RampElection, name: " RampElection" },
    rrs: { class: RampRefiling, name: " RampRefiling" },
    scs: { class: SupplementalClaim, name: " SupplementalClaims" }
  }.freeze

  ##
  # Runs methods to find duplicates, update relations, and delete extra veteran record.
  ##
  def run_remediation
    return unless log_and_get_relations_count

    return unless relations_updated?

    nil unless duplicate_veteran_deleted?
  end

  ##
  # Gathers relations associated with duplicate file number and correct file number
  # stores the relations and their count in a hash and logs results to the console.
  ##
  def log_and_get_relations_count
    success = valid_vet_count?(@duplicate_veteran_file_number)
    success = duplicate_vet_pair_set?(duplicate_veterans, @duplicate_veteran_file_number) if success
    success = valid_file_number?(correct_file_number_by_ssn, @correct_veteran.file_number) if success

    if success
      get_relations_count(@duplicate_veteran_file_number, duplicate_veteran.id, "duplicate_veteran_file_number")
      get_relations_count(correct_file_number_by_ssn, duplicate_veteran.id, "correct_file_number")
      send_log(@duplicate_relations_count_log)
      send_log(@remaining_relations_count_log)
    end

    success
  end

  ##
  # Gathers logs to send to stuck_job_report_service.logs
  ##
  def fixer_logs
    [
      @duplicate_relations_count_log,
      @correct_relations_count_log,
      @updated_relations_count_log,
      @remaining_relations_count_log,
      @failure_log
    ].map(&:join)
  end

  private

  ##
  # Updates relations associated with duplicate veteran record
  # to use BGS - correct - file number.
  # Logs updated relations count
  # Check for remaining duplicate relations
  # Logs remaining relations count
  ##
  def relations_updated?
    las = @duplicate_relations[:las][:relations].first

    change_legacy_to_use_vbms_id(las, vbms_id) if !las.blank?

    unless file_numbers_updated?(correct_file_number_by_ssn, vbms_id, @duplicate_veteran_file_number)
      Rails.logger.error("There were differences in duplicate relations and update relations.")
      send_log(@updated_relations_count_log)
      return false
    end

    send_log(@updated_relations_count_log)
    true
  end

  ##
  # Deletes duplicate veteran
  ##
  def duplicate_veteran_deleted?
    file_number = @duplicate_veteran_file_number
    if remaining_duplicates?(file_number)
      message = "Duplicate veteran still has associated records. Can not delete until resolved."
      Rails.logger.error("#{message} #{@remaining_relations_count_log.join}")
      send_log(@remaining_relations_count_log)
      return false
    else
      duplicate_veteran.destroy!
      Rails.logger.info("Veteran deleted successfuly")
    end
    true
  end

  def duplicate_veteran
    Veteran.find_by(file_number: @duplicate_veteran_file_number)
  end

  def duplicate_veterans
    @duplicate_veterans ||= Veteran.where("ssn = ? or participant_id = ?", duplicate_veteran.ssn,
                                          duplicate_veteran.participant_id)
  end

  def vet_ssn
    duplicate_veteran.ssn
  end

  def correct_file_number_by_ssn
    @correct_file_number_by_ssn ||= BGSService.new.fetch_file_number_by_ssn(vet_ssn)
  end

  def vbms_id
    @vbms_id ||= LegacyAppeal.convert_file_number_to_vacols(correct_file_number_by_ssn)
  end

  ##
  # Get list of relations
  # Iterates over list of relations and gets a list of relations for each
  # relation type. Uses a reference number that can be a file number or a vbms id.
  # Returns an array of objects of the relation class.
  # obtains a list of instances of relation based on reference number provided
  # @param [String] reference number. A vbms id for f8s, and las. Duplicate veteran id for is_vi.
  # File number for the rest.
  # @param [Symbol] a symbol with abbreviated name of relation class.
  ##
  def get_relation_list(relation_type, reference_number)
    case relation_type
    when :is_vi
      RELATIONS[relation_type][:class].where(veteran_id: reference_number)
    when :las
      RELATIONS[relation_type][:class].where(vbms_id: convert_file_number_to_legacy(reference_number))
    when :f8s
      RELATIONS[relation_type][:class].where(file_number: convert_file_number_to_legacy(reference_number))
    when :bpoas, :ds
      RELATIONS[relation_type][:class].where(file_number: reference_number)
    else
      RELATIONS[relation_type][:class].where(veteran_file_number: reference_number)
    end
  end

  ##
  # Calls get_relation_list method passing the right argument
  # depending on whether the relation is an Intake by veteran id or
  # something else.
  # Obtains list of relations
  # @param [Symbol] relation abbreation from hash. As symbol.
  # @param [String] file number
  # @param [String] veteran id
  ##
  def find_list_based_on_identifier(rel, file_number, veteran_id)
    if rel == :is_vi
      get_relation_list(rel, veteran_id)
    else
      get_relation_list(rel, file_number)
    end
  end

  ##
  # Gets a count for each relation found based on the identifer provided and
  # logs the count by concatenating a description to the corresponding log variable.
  # Form of identifiers can be: duplicate veteran file number, bgs file number, veteran id.
  # Gets relation count and logs it
  # @param [String] file number
  # @param [String] veteran id
  # @param [String] file type description
  ##
  def get_relations_count(file_number, veteran_id, file_type)
    case file_type
    when "duplicate_veteran_file_number"
      RELATIONS.each_key do |rel, _value|
        rels = find_list_based_on_identifier(rel, file_number, veteran_id)
        @duplicate_relations[rel] = { relations: rels, count: rels.length }
        message = "#{rels.count}#{log_count(rel)}"
        @duplicate_relations_count_log.push(message) # unless @duplicate_relations_count_log.nil?
      end
    when "bgs_file_number"
      RELATIONS.each_key do |rel, _value|
        rels = find_list_based_on_identifier(rel, file_number, veteran_id)
        @correct_relations[rel] = { relations: rels, count: rels.length }
        message = "#{rels.count}#{log_count(rel)}"
        @correct_relations_count_log.push(message)
      end
    end
  end

  ##
  # Checks BGS file number matches correct veteran file number
  # @param [String] bgs file number
  # @param [String] correct veteran file number
  ##
  def valid_file_number?(bgs_file_number, vet_file_number)
    if bgs_file_number != vet_file_number
      message = "File number from BGS does not match correct veteran record."
      update_failure_log(message)
      return false
    end
    true
  end

  ##
  # Changes legacy appeals case records to use vbms_id
  # @param [Object] list of legacy appeals relations with duplicate file number
  # @param [String] vbms id
  # :reek:UtilityFunction
  ##
  def change_legacy_to_use_vbms_id(las, vbms_id)
    las.case_record.update!(bfcorlid: vbms_id)
    las.case_record.folder.update!(titrnum: vbms_id)
    las.case_record.correspondent.update!(slogid: vbms_id)
  end

  ##
  # Checks it updated correctly
  # If not updated correclty add to log
  # @param [Symbol] relation symbol to use as key in logs hash
  # @param [Integer] relation count with duplicate veteran file number.
  # @param [Integer] relation count after update.
  # @param [Integer] pre-existing relation count.
  # :reek:FeatureEnvy
  ##
  def updated?(args)
    correct_count = args[:correct_count]
    relation = args[:relation]
    updated_relations = (correct_count >= 1) ? correct_count - args[:pre_existing_count] : correct_count

    if updated_relations == args[:dup_count]
      log_update(relation, args[:dup_count], updated_relations)
      message = "#{RELATIONS[relation][:name]} did not update."
      Rails.logger.info(message)
      failure_log(message)
      return false
    end

    Rails.logger.info "---------"
    Rails.logger.info "Updated: #{updated_relations} #{RELATIONS[relation][:name]}"
    Rails.logger.info "---------"
    true
  end

  ##
  # Updates relations by replacing duplicate file number with bgs file number or vbms_id
  # Creates a list of correct relations
  # Logs the count for each correct relation to the 'correct_relations_count_log' log.
  # Updates relations by bgs file number and vbms_id.
  # @param [String] bgs file number
  # @param [String] vbms id.
  # @param [String] duplicate veteran file number
  ##
  def file_numbers_updated?(file_number, vbms_id, dp_vet_file_num)
    RELATIONS.each_key do |rel, _value|
      dup_file_num_relations_count = find_list_based_on_identifier(rel, dp_vet_file_num, duplicate_veteran.id).count
      existing_bgs_relations = find_list_based_on_identifier(rel, file_number, duplicate_veteran.id).count

      next if existing_bgs_relations >= 1 && [:hlrs, :is_fn].include?(rel)

      if [:las, :f8s].include?(rel)
        update_relation_by_vbms_id(rel, vbms_id, dp_vet_file_num)
      else
        update_relation_by_file_number(rel, file_number, dp_vet_file_num)
      end

      rels = find_list_based_on_identifier(rel, file_number, vbms_id)
      @correct_relations[rel] = { relations: rels, count: rels.length }
      correct_file_count = @correct_relations[rel][:count]

      checker_args = { rel: rel, correct: correct_file_count, dup: dup_file_num_relations_count,
                       pre: existing_bgs_relations }
      return false unless updated?(relation_and_counts(checker_args))
    end
    true
  end

  ##
  # Returns a hash of arguments for updates checker
  # @param [Symbol] - symbol from RELATIONS key. i.e. :as, :las, etc
  # @param [Integer] - Correct relations count after update
  # @param [Integer] - Duplicate relations count based on duplicate vet file number
  # @param [Integer] - Pre-existing relations count based on BGS file number
  # :reek:UtilityFunction
  ##
  def relation_and_counts(args)
    {
      relation: args[:rel],
      correct_count: args[:correct],
      dup__count: args[:dup],
      pre_existing_count: args[:pre]
    }
  end

  ##
  # Update veteran_file_number with provided file number
  # Iterates over provided list of relation and replaces current veteran_file_number
  # with bgs veteran file number.
  # @param [String] RELATIONS key for relation type
  # @param [String] bgs file number
  # @param [String] duplicate veteran file number
  # :reek:FeatureEnvy
  ##
  def update_relation_by_file_number(relation_type, file_number, dp_vet_file_num)
    relations_to_be_updated = get_relation_list(relation_type, dp_vet_file_num)

    if [:bpoas, :ds].include?(relation_type)
      relations_to_be_updated.update_all(file_number: file_number)
    else
      relations_to_be_updated.update_all(veteran_file_number: file_number)
    end
  end

  ##
  # Update vbms id with provided id
  # Iterates over provided list of relation and replaces current vbms_id
  # with vbms id number.
  # @param [String] RELATIONS key for relation type
  # @param [String] vbms id
  # @param [String] duplicate veteran file number
  # :reek:FeatureEnvy
  ##
  def update_relation_by_vbms_id(relation_type, vbms_id, dp_vet_file_num)
    relations_to_be_updated = get_relation_list(relation_type, dp_vet_file_num)
    if relation_type == :f8s
      relations_to_be_updated.update_all(file_number: vbms_id)
    else
      relations_to_be_updated.update_all(vbms_id: vbms_id)
    end
  end

  ##
  # Checks whether relations exist using the old file number
  # if relations count is not zero adds to reporting log @remaining_relations_count_log
  # Searchs relations with old number and adds to log if they exist.
  # @param [String] old file number - duplicate veteran file number.
  ##
  def remaining_duplicates?(duplicate_file_number)
    if @remaining_relations_count_log.length != 1
      @remaining_relations_count_log = ["Remaining Duplicate Relations:\n "]
    end

    RELATIONS.each_key do |rel, _value|
      rels = find_list_based_on_identifier(rel, duplicate_file_number, duplicate_veteran.id)
      next if rels.count == 0

      message = "#{rels.count}#{log_count(rel)}"
      @remaining_relations_count_log.push(message)
    end
    if @remaining_relations_count_log.length == 1
      Rails.logger.info("No remaining relations with duplicate veteran file number")
      return false
    end

    Rails.logger.info("Remaining Relations:\n#{@remaining_relations_count_log.join}")
    true
  end

  ##
  # Checks there is only one veteran with bad file number
  # @param [String] duplicate veteran file number
  ##
  def valid_vet_count?(duplicate_veteran_file_number)
    vets = vets_count(duplicate_veteran_file_number)

    if vets.zero?
      message = "No vets found with this file number."
      update_failure_log(message)
      return false
    end

    if vets > 1
      message_more_than_one = "More than one duplicate veteran file number exists."
      update_failure_log(message_more_than_one)
      return false
    end
    true
  end

  ##
  # Gets veterans count with file number provided
  # Returns and count as an integer
  # @params [string] Veteran file number
  ##
  def vets_count(file_number)
    Veteran.where(file_number: file_number).count
  end

  ##
  # Adds error message to failure_log
  # Logs message to stack trace
  # @param [String]
  ##
  def update_failure_log(message)
    @failure_log.push(message)
    Rails.logger.error(message)
  end

  ##
  # Sets duplicate pair
  # @param [Array] Instances of veterans where ssn or participant id matches
  #  veteran found using duplicate number.
  # @param [String] Duplicate veteran file number
  ##
  def duplicate_vet_pair_set?(dp_vets, old_file_num)
    if pair_is_duplicate?(dp_vets)
      other_v = dp_vets.first
      if other_v.file_number == old_file_num
        other_v = dp_vets.last
      end
      duplicate_vet_ssn(other_v)
      @correct_veteran = other_v
      return true
    end
    false
  end

  ##
  # Checks veteran is a pair
  # @param [Array] Array of veteran objects
  # :reek:FeatureEnvy
  ##
  def pair_is_duplicate?(dp_vets)
    if dp_vets.count < 2
      message = "No duplicate veteran found."
      update_failure_log(message)
      return false
    end
    if dp_vets.count > 2
      message = "More than two veterans found."
      update_failure_log(message)
      return false
    end
    dp_vets.count == 2
  end

  ##
  # Converts file number to vacols
  # @param [String] file number
  # :reek:UtilityFunction
  ##
  def convert_file_number_to_legacy(file_number)
    LegacyAppeal.convert_file_number_to_vacols(file_number)
  end

  ##
  # Validates veteran instance and returns veteran ssn
  # @params [Object] Veteran instance
  ##
  def duplicate_vet_ssn(other_v)
    validate_dup_vet(other_v)
    if duplicate_veteran.ssn.empty? && !other_v.ssn.empty?
      other_v.ssn
    else
      duplicate_veteran.ssn
    end
  end

  ##
  # Checks a Veteran instance has a file number and social security number
  # @params [Object] Veteran object
  ##
  def validate_dup_vet(other_v)
    if same_or_no_file_number(other_vet: other_v, duplicate_veteran_file_number: @duplicate_veteran_file_number)
      update_failure_log("Both veterans have the same file_number or No file_number on the correct veteran.")
    elsif ssn_empty?(other_v)
      update_failure_log("Neither veteran has a ssn and a ssn is needed to check the BGS file number.")
    elsif same_ssn?(other_v)
      update_failure_log("Veterans do not have the same ssn and a correct ssn needs to be chosen.")
    end
  end

  ##
  # Check veterans have a file number and is different from each others
  # @params [Object] - Veteran object. Second dup veteran.
  # @params [String] - duplicate veteran file number
  # :reek:UtilityFunction
  ##
  def same_or_no_file_number(args)
    other_v = args[:other_vet]
    other_v.file_number.empty? || other_v.file_number == args[:duplicate_veteran_file_number]
  end

  ##
  # Check ssn numbers are not empty
  # @params [Object] - Veteran object. Second dup veteran.
  ##
  def ssn_empty?(other_v)
    duplicate_veteran.ssn.empty? && other_v.ssn.empty?
  end

  ##
  # Check ssn numbers are not the same
  # @params [Object] - Veteran object. Second dup veteran.
  # :reek:FeatureEnvy
  ##
  def same_ssn?(other_v)
    !other_v.ssn.empty? && duplicate_veteran.ssn != other_v.ssn
  end

  ##
  # Add relation name to relations count log
  # @param [Symbol] - relation name abbreation symbol
  ##
  def log_count(rel)
    "#{RELATIONS[rel][:name]}\n"
  end

  ##
  # Add relation update data to relations update log
  # @param [Symbol] - relation name abbreation symbol
  # @param [Integer] - duplicate count
  # @param [Integer] - updated count
  ##
  def log_update(rel, dup_count, update_count)
    @updated_relations_count_log.push(
      "Expected #{dup_count}  #{RELATIONS[rel][:name]} updated, but #{update_count}  were updated.\n"
    )
  end

  ##
  # @param [array] - log variable array
  ##
  def send_log(log)
    Rails.logger.info log.join
  end
end
