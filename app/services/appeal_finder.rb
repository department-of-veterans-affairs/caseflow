# frozen_string_literal: true

class AppealFinder
  class << self
    def find_appeals_with_file_numbers(file_numbers)
      return [] if file_numbers.empty?

      MetricsService.record("VACOLS: Get appeal information for file_numbers #{file_numbers}",
                            service: :queue,
                            name: "VeteranFinderQuery.find_appeals_with_file_numbers") do
        appeals = Appeal.established.where(veteran_file_number: file_numbers).to_a
        begin
          appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(*file_numbers))
        rescue ActiveRecord::RecordNotFound
          # file number could not be found. don't raise exception and not return, just ignore.
        end
        appeals
      end
    end

    # All Appeals have stream_docket_number populated either with their own
    # docket number (original appeals), or with the original appeal's docket
    # number (new appeal streams). This will thus return both the original
    # and all appeal streams off of it. Docket number of appeal streams is
    # never shown and thus the inability to search for it is OK.
    def find_appeals_by_docket_number(docket_number)
      Appeal.where(stream_docket_number: docket_number)
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
end
