# frozen_string_literal: true

class VeteranFinderQuery
  def initialize(user:)
    @user = user
  end

  def find_appeals_for_veterans(veterans:)
    if user.vso_employee?
      find_appeals_for_vso_user(veterans: veterans)
    else
      self.class.find_appeals_with_file_numbers(
        file_numbers: veterans.map(&:file_number)
      )
    end
  end

  def find_appeals_by_ssn_or_file_number(file_number_or_ssn:)
    find_appeals_for_veterans(
      veterans: self.class.find_by_ssn_or_file_number(file_number_or_ssn: file_number_or_ssn)
    )
  end

  class << self
    def find_by_ssn_or_file_number(file_number_or_ssn:)
      # Multiple possibilities:
      #
      #   1. The input is an SSN or File Number that maps directly to the `file_number`
      #      field for a vet.
      #   2. The input is an SSN that requires a BGS lookup for the File Number.
      #   3. Combination of both.
      veteran_file_number_or_ssn = Veteran.find_by(file_number: file_number_or_ssn)
      veteran_bgs_lookup = if file_number_or_ssn.length == 9
                             Veteran.find_by_file_number_or_ssn(file_number_or_ssn)
                           end

      [veteran_file_number_or_ssn, veteran_bgs_lookup].select { |vet| !vet.nil? }.uniq(&:id)
    end

    def find_appeals_with_file_numbers(file_numbers:)
      return [] if file_numbers.empty?

      MetricsService.record("VACOLS: Get appeal information for file_numbers #{file_numbers}",
                            service: :queue,
                            name: "VeteranFinderQuery.find_appeals_with_file_numbers") do
        appeals = Appeal.where(veteran_file_number: file_numbers).reject(&:removed?).to_a
        # rubocop:disable Lint/HandleExceptions
        begin
          appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(*file_numbers))
        rescue ActiveRecord::RecordNotFound
        end
        # rubocop:enable Lint/HandleExceptions
        appeals
      end
    end
  end

  private

  attr_accessor :user

  def find_appeals_for_vso_user(veterans:)
    return [] if veterans.empty?

    MetricsService.record("VACOLS: Get vso appeals information for veterans",
                          service: :queue,
                          name: "VeteranFinderQuery.find_appeals_for_vso_user") do
      vso_participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veterans.flat_map { |vet| vet.accessible_appeals_for_poa(vso_participant_ids) }
    end
  end
end
