# frozen_string_literal: true

class AppealsForFileNumber
  def initialize(file_number:, user:, veteran:)
    @file_number = file_number
    @user = user
    @veteran = veteran
  end

  def call
    @appeals = user.vso_employee? ? vso_appeals_for_file_number : appeals_for_file_number

    json_appeals
  end

  private

  attr_reader :file_number, :user, :appeals, :veteran

  def appeals_for_file_number
    MetricsService.record("VACOLS: Get appeal information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsForFileNumber.appeals_for_file_number") do

      appeals = Appeal.where(veteran_file_number: file_number).to_a
      # rubocop:disable Lint/HandleExceptions
      begin
        appeals.concat(LegacyAppeal.fetch_appeals_by_file_number(file_number))
      rescue ActiveRecord::RecordNotFound
      end
      # rubocop:enable Lint/HandleExceptions
      appeals
    end
  end

  def vso_appeals_for_file_number
    MetricsService.record("VACOLS: Get vso appeals information for file_number #{file_number}",
                          service: :queue,
                          name: "AppealsForFileNumber.vso_appeals_for_file_number") do
      vso_participant_ids = user.vsos_user_represents.map { |poa| poa[:participant_id] }

      veteran.accessible_appeals_for_poa(vso_participant_ids)
    end
  end

  def json_appeals
    ama_appeals, legacy_appeals = appeals.partition { |appeal| appeal.is_a?(Appeal) }
    ama_hash = WorkQueue::AppealSerializer.new(
      ama_appeals, is_collection: true, params: { user: current_user }
    ).serializable_hash

    legacy_hash = WorkQueue::LegacyAppealSerializer.new(
      legacy_appeals, is_collection: true, params: { user: current_user }
    ).serializable_hash

    ama_hash[:data].concat(legacy_hash[:data])
  end
end
