# frozen_string_literal: true

class AppealFinder
  def initialize(user:)
    @user = user
  end

  def find_appeals_for_veterans(veterans)
    return [] if veterans.empty?

    if user.vso_employee?
      find_appeals_for_vso_user(veterans: veterans)
    else
      self.class.find_appeals_with_file_numbers(
        veterans.map(&:file_number)
      )
    end
  end

  def find_appeals_by_ssn_or_file_number(file_number_or_ssn)
    find_appeals_for_veterans(
      veterans: VeteranFinder.find_or_create_all(file_number_or_ssn)
    )
  end

  def find_appeal_by_docket_number(docket_number)
    return [] if docket_number.empty?

    # Take the first six digits as date, remaining as ID
    parsed = docket_number.split("-")

    # If we can't parse a valid date from search, return no results
    begin
      receipt_date = Date.strptime(parsed[0], "%y%m%d")

      id = parsed[1]
      appeal = Appeal.find_by(id: id, receipt_date: receipt_date)

      appeal
      # # If VSO user, check to make sure they have rights to the requested appeal
      # if user.vso_employee?
      #   veterans = VeteranFinder.find_or_create_all(appeal.veteran_file_number)

      #   filter_appeals_for_vso_user(appeals: Array.wrap(appeal), veterans: veterans)
      # else
      #   appeal
      # end
    rescue ArgumentError
      return nil
    end
  end

  class << self
    def find_appeals_with_file_numbers(file_numbers)
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
    MetricsService.record("VACOLS: Get vso appeals information for veterans",
                          service: :queue,
                          name: "VeteranFinderQuery.find_appeals_for_vso_user") do
      vso_participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veterans.flat_map { |vet| vet.accessible_appeals_for_poa(vso_participant_ids) }
    end
  end

  def filter_appeals_for_vso_user(appeals:, veterans:)
    allowed_appeal_ids = find_appeals_for_vso_user(veterans: veterans).map(&:id)

    appeals.select do |appeal|
      allowed_appeal_ids.include?(appeal.id)
    end
  end
end
