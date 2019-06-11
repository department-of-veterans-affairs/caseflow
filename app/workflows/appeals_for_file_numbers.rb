# frozen_string_literal: true

class AppealsForFileNumbers
  def initialize(file_numbers:, user:, veteran:)
    @file_numbers = file_numbers
    @user = user
    @veteran = veteran
  end

  def call
    @appeals = user.vso_employee? ? vso_appeals_for_file_numbers : appeals_for_file_numbers

    json_appeals
  end

  private

  attr_reader :file_numbers, :user, :appeals, :veteran

  def appeals_for_file_numbers
    MetricsService.record("VACOLS: Get appeal information for file_numbers #{file_numbers}",
                          service: :queue,
                          name: "AppealsForFileNumbers.appeals_for_file_numbers") do

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

  def vso_appeals_for_file_numbers
    MetricsService.record("VACOLS: Get vso appeals information for file_numbers #{file_numbers}",
                          service: :queue,
                          name: "AppealsForFileNumbers.vso_appeals_for_file_numbers") do
      vso_participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veteran.accessible_appeals_for_poa(vso_participant_ids)
    end
  end

  def json_appeals
    ama_appeals, legacy_appeals = appeals.partition { |appeal| appeal.is_a?(Appeal) }
    ama_hash = WorkQueue::AppealSerializer.new(
      ama_appeals, is_collection: true, params: { user: user }
    ).serializable_hash

    legacy_hash = WorkQueue::LegacyAppealSerializer.new(
      legacy_appeals, is_collection: true, params: { user: user }
    ).serializable_hash

    ama_hash[:data].concat(legacy_hash[:data])
  end
end
