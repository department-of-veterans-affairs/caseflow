# frozen_string_literal: true

class FixFileNumberWizard

  ASSOCIATIONS = [
    Appeal,
    AvailableHearingLocations,
    BgsPowerOfAttorney,
    Document,
    EndProductEstablishment,
    Form8,
    HigherLevelReview,
    Intake,
    LegacyAppeal,
    RampElection,
    RampRefiling,
    SupplementalClaim]

  class Collection
    attr_accessor :klass, :records, :column
    delegate :count, to: :records

    def initialize(klass, old_file_number)
      @klass = klass
      @column = if klass == LegacyAppeal
                  "vbms_id"
                else
                  klass.column_names.find { |name| name.end_with?("file_number") }
                end
      @records = klass.where("#{column}": maybe_convert_file_number(old_file_number))
    end

    def maybe_convert_file_number(file_number)
      if [LegacyAppeal, Form8].include?(klass)
        LegacyAppeal.convert_file_number_to_vacols(file_number)
      else
        file_number
      end
    end

    def update!(file_number)
      new_value = maybe_convert_file_number(file_number)
      if klass == LegacyAppeal
        records.each do |legapp|
          legapp.case_record.update!(bfcorlid: new_value)
          legapp.case_record.folder.update!(titrnum: new_value)
          legapp.case_record.correspondent.update!(slogid: new_value)
        end
      end
      records.update_all("#{column}": new_value)
    end
  end

  class << self
    def run(*args, veteran: nil, ssn: nil, appeal: nil)
      arg_count = [veteran, ssn, appeal].compact.count
      if args.any? || arg_count == 0 || arg_count > 1
        puts "Please supply exactly one named argument: veteran, ssn, appeal. Examples:"
        puts "> FixFileNumberWizard.run(veteran: Veteran.find(1234))"
        puts "> FixFileNumberWizard.run(ssn: '123456789')"
        puts "> FixFileNumberWizard.run(appeal: Appeal.find_by(stream_docket_number: '190219-0001'))"
        return
      end
      if ssn.present?
        veteran = Veteran.find_by(ssn: ssn)
      elsif appeal.present?
        veteran = appeal.veteran
      end
      FixFileNumberWizard.new(veteran).call
    end
  end

  attr_reader :veteran

  def initialize(veteran)
    @veteran = veteran
  end

  def call
    if veteran.ssn != veteran.file_number
      puts "Veteran's file number is different from SSN. This may be already fixed, or another situation."
      return
    end

    RequestStore[:current_user] = User.system_user if RequestStore[:current_user].nil?

    file_number = BGSService.new.fetch_file_number_by_ssn(veteran.ssn)
    if file_number == veteran.file_number
      puts "Veteran's file number is already up-to-date."
      return
    elsif file_number.nil?
      puts "Veteran's file number could not be found in BGS."
      return
    elsif Veteran.find_by(file_number: file_number).present?
      puts "Duplicate veteran record found. Handling this scenario is not supported yet."
      return
    end

    collections = ASSOCIATIONS.map { |klass| Collection.new(klass, veteran.ssn) }
    if collections.map(&:count).sum == 0
      puts "No associated records found for the current file number. Aborting because this is very strange."
      return
    end

    prompt = "Updating this file number will also update the following associated records:\n"
    collections.each do |collection|
      prompt += "#{collection.count} #{collection.klass.name} records\n" if collection.count > 0
    end
    return unless get_input(prompt + "Continue") == 'y'

    collections.each { |collection| collection.update!(file_number) }
    veteran.update!(file_number: file_number)
  rescue Interrupt => err
  end

  def get_input(prompt, *opts)
    opts << ['y', 'yes; continue'] if opts.empty?
    opts << ['q', 'quit; do not continue any further']
    input_chars = opts.map(&:first)
    loop do
      print "#{prompt} [#{input_chars.join(',')},?]? "
      input = gets[0]
      unless input_chars.include?(input)
        opts.each do |opt|
          puts "#{opt[0]} - #{opt[1]}"
        end
        puts "? - print help"
        next
      end
      raise Interrupt if input == 'q'
      return input
    end
  end
end
