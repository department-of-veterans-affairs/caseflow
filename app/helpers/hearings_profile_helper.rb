# frozen_string_literal: true

module HearingsProfileHelper
  class << self
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/MethodLength
    def profile_data(current_user = nil, *args)
      options = args.extract_options!
      limit = options[:limit] || 20
      after = options[:after] || Time.zone.local(2020, 4, 1)

      ama_hearings_details = []
      legacy_hearings_details = []

      hearing_disposition_tasks.each do |task|
        next unless task_is_after_time?(task, after)

        if legacy_outside_eastern?(task) && legacy_hearings_details.count < limit
          legacy_hearings_details << hearing_detail(task.hearing)
        elsif ama_outside_eastern?(task) && ama_hearings_details.count < limit
          ama_hearings_details << hearing_detail(task.hearing)
        end

        break if legacy_hearings_details.count >= limit && ama_hearings_details.count >= limit
      rescue StandardError => error
        Rails.logger.info "HearingsProfileHelper error: #{error.message}"
      end

      {
        profile: profile(current_user),
        hearings: {
          ama_hearings: ama_hearings_details,
          legacy_hearings: legacy_hearings_details
        }
      }
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    private

    def hearing_disposition_tasks
      Task.active.where(type: AssignHearingDispositionTask.name).order(:id)
    end

    def task_is_after_time?(task, after)
      task&.hearing&.scheduled_for &.> after
    end

    def legacy_outside_eastern?(task)
      task.appeal_type == LegacyAppeal.name && timezone_outside_eastern?(task)
    end

    def ama_outside_eastern?(task)
      task.appeal_type == Appeal.name && timezone_outside_eastern?(task)
    end

    def timezone_outside_eastern?(task)
      !!(task.hearing&.regional_office&.timezone &.!= "America/New_York")
    end

    def profile(current_user = nil)
      {
        current_user_css_id: current_user&.css_id,
        current_user_timezone: current_user&.timezone,
        time_zone_name: Time.zone.name,
        config_time_zone: Rails.configuration.time_zone
      }
    end

    def hearing_detail(hearing)
      {
        id: hearing.id,
        type: hearing.class.name,
        external_id: hearing.external_id,
        created_by_timezone: hearing.created_by&.timezone,
        central_office_time_string: hearing.central_office_time_string,
        scheduled_time_string: hearing.scheduled_time_string,
        scheduled_for: hearing.scheduled_for,
        scheduled_time: hearing.scheduled_time
      }
    end
  end
end
