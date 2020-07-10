# frozen_string_literal: true

class AppealFinder
  class << self
    def find_appeals_with_file_numbers(file_numbers)
      return [] if file_numbers.empty?

      MetricsService.record("VACOLS: Get appeal information for file_numbers #{file_numbers}",
                            service: :queue,
                            name: "VeteranFinderQuery.find_appeals_with_file_numbers") do
        appeals = Appeal.established.where(veteran_file_number: file_numbers).reject(&:removed?).to_a
        begin
          appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(*file_numbers))
        rescue ActiveRecord::RecordNotFound
          # file number could not be found. don't raise exception and not return, just ignore.
        end
        appeals
      end
    end

    def find_appeal_by_docket_number(docket_number)
      return [] unless docket_number

      # Take the first six digits as date, remaining as ID
      parsed = docket_number.split("-")

      # If we can't parse a valid date from search, return no results
      begin
        receipt_date = Date.strptime(parsed[0], "%y%m%d")

        id = parsed[1]
        appeal = Appeal.find_by(id: id, receipt_date: receipt_date)

        appeal
      rescue ArgumentError
        nil
      end
    end
  end

  def initialize(user:)
    @user = user
  end

  def find_appeals_for_veterans(veterans)
    return [] if veterans.empty?

    if user.vso_employee?
      find_appeals_for_vso_user(veterans: veterans)
    else
      self.class.find_appeals_with_file_numbers(
        [veterans.map(&:file_number), veterans.map(&:ssn)].flatten.compact.uniq
      )
    end
  end

  private

  attr_reader :user

  def find_appeals_for_vso_user(veterans:)
    MetricsService.record("VACOLS: Get vso appeals information for veterans",
                          service: :queue,
                          name: "VeteranFinderQuery.find_appeals_for_vso_user") do
      vso_participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veterans.flat_map do |vet|
        AppealsForPOA.new(veteran_file_number: vet.file_number, poa_participant_ids: vso_participant_ids).call
      end
    end
  end

  def filter_appeals_for_vso_user(appeals:, veterans:)
    allowed_appeal_ids = find_appeals_for_vso_user(veterans: veterans).map(&:id)

    appeals.select do |appeal|
      allowed_appeal_ids.include?(appeal.id)
    end
  end
end
