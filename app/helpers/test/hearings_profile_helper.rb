# frozen_string_literal: true

module Test::HearingsProfileHelper
  class << self
    attr_reader :limit, :after, :include_eastern, :user

    def profile_data(current_user = nil, *args)
      configure_helper(current_user, args)

      select_hearings

      hearings_profile
    end

    private

    def configure_helper(current_user, args)
      @user = current_user

      options = args.extract_options!
      @limit = options[:limit] || 20
      @after = options[:after] || Time.zone.local(2020, 4, 1)
      @include_eastern = options[:include_eastern] || false

      @ama_hearings_details = []
      @legacy_hearings_details = []
    end

    def select_hearings
      hearing_disposition_tasks.each do |task|
        sort_task(task)

        break if limit_has_been_reached
      end
    end

    def hearings_profile
      {
        profile: profile,
        hearings: {
          ama_hearings: ama_hearings_details,
          legacy_hearings: legacy_hearings_details
        }
      }
    end

    def hearing_disposition_tasks
      Task.active.where(type: AssignHearingDispositionTask.name).order(:id)
    end

    def sort_task(task)
      if qualified_legacy_hearing?(task) && legacy_hearings_details.count < limit
        legacy_hearings_details << hearing_detail(task.hearing)
      elsif qualified_ama_hearing?(task) && ama_hearings_details.count < limit
        ama_hearings_details << hearing_detail(task.hearing)
      end
    rescue StandardError => error
      Rails.logger.error "Test::HearingsProfileHelper error: #{error.message}"
    end

    def limit_has_been_reached
      legacy_hearings_details.count >= limit && ama_hearings_details.count >= limit
    end

    def timezone_outside_eastern?(task)
      !!(task.hearing&.regional_office&.timezone &.!= "America/New_York")
    end

    def hearing_is_scheduled_after_time?(task)
      task&.hearing&.scheduled_for &.> after
    end

    def qualified_hearing?(task)
      hearing_is_scheduled_after_time?(task) && (include_eastern || timezone_outside_eastern?(task))
    end

    def qualified_legacy_hearing?(task)
      task.appeal_type == LegacyAppeal.name && qualified_hearing?(task)
    end

    def qualified_ama_hearing?(task)
      task.appeal_type == Appeal.name && qualified_hearing?(task)
    end

    def profile
      {
        config_time_zone: Rails.configuration.time_zone,
        current_user_css_id: user&.css_id,
        current_user_timezone: user&.timezone,
        time_zone_name: Time.zone.name
      }
    end

    def hearing_detail(hearing)
      {
        central_office_time_string: hearing.central_office_time_string,
        created_by_timezone: hearing.created_by&.timezone,
        external_id: hearing.external_id,
        regional_office_timezone: hearing.regional_office&.timezone,
        request_type: hearing.hearing_day&.request_type,
        scheduled_for: hearing.scheduled_for,
        scheduled_time: hearing.scheduled_time,
        scheduled_time_string: hearing.scheduled_time_string,
        unique_id: "#{hearing.class.name.downcase}-#{hearing.id}"
      }
    end

    def ama_hearings_details
      @ama_hearings_details ||= []
    end

    def legacy_hearings_details
      @legacy_hearings_details ||= []
    end
  end
end
