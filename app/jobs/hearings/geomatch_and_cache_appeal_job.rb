# frozen_string_literal: true

class Hearings::GeomatchAndCacheAppealJob < ApplicationJob
  queue_with_priority :high_priority
  application_attr :hearing_schedule

  # :nocov:
  retry_on(StandardError, wait: 10.seconds, attempts: 10) do |job, exception|
    Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception}")

    if job.executions == 10
      kwargs = job.arguments.first
      extra = {
        application: job.class.app_name.to_s,
        appeal_id: kwargs[:appeal_id],
        job_id: job.job_id
      }

      Raven.capture_exception(exception, extra: extra)
    end
  end

  discard_on(ArgumentError)
  # :nocov:

  def perform(appeal_id:, appeal_type:)
    @appeal = appeal_type.constantize.find(appeal_id)

    begin
      GeomatchService.new(appeal: appeal).geomatch if appeal.closest_regional_office.nil?
    rescue StandardError
      if appeal.closest_regional_office.nil?
        raise
      end

      # If geomatching fails, but there is already a closest regional office,
      # the data can still be cached.
    end

    cache_appeal_attributes(appeal_type)
  end

  private

  attr_reader :appeal

  def cache_appeal_attributes(appeal_type)
    appeal.reload

    if appeal.closest_regional_office.present?
      cached_appeal_service = CachedAppealService.new

      if appeal_type == LegacyAppeal.name
        cached_appeal_service.cache_legacy_appeal_postgres_data([appeal])
        cached_appeal_service.cache_legacy_appeal_vacols_data([appeal.vacols_id])
      else
        cached_appeal_service.cache_ama_appeals([appeal])
      end
    end
  end
end
