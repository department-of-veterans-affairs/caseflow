# frozen_string_literal: true

namespace :data_migrations do
  class HearingDayModelNotInCorrectState < StandardError; end

  # description:
  #   This task is built for a one-time migration of created and updated by information on HearingDay
  #   objects. It expects HearingDay objects to have created_by and updated_by columns containing
  #   user css_ids, and created_by_id and updated_by_id columns which can be used to refer to the
  #   user(s) with those css_ids. If a HearingDay already has created/updated_by_id, this task will
  #   not alter it.
  #
  # usage:
  #   $ bundle exec rake data_migrations:migrate_hearing_day_created_and_updated_by[false]"
  desc "set created_by_id and updated_by_id on hearing days with css_ids in created_by and updated_by"
  task :migrate_hearing_day_created_and_updated_by, [:dry_run] => :environment do |_, args|
    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"

    Rails.logger.tagged("rake data_migrations:migrate_hearing_day_created_and_updated_by") do
      if dry_run
        Rails.logger.info("Starting dry run")
      else
        Rails.logger.info("Starting migration")
      end
    end

    if dry_run
      puts "*** DRY RUN"
      puts "*** pass 'false' as the first argument to execute"
    end

    # make sure the HearingDay model is in the correct state
    required_column_names = %w[created_by updated_by created_by_id updated_by_id]
    has_required_columns = (HearingDay.column_names & required_column_names).size == required_column_names.size
    has_no_associations = HearingDay.reflect_on_association(:created_by).blank? &&
                          HearingDay.reflect_on_association(:updated_by).blank?

    unless has_required_columns && has_no_associations
      fail HearingDayModelNotInCorrectState, "The HearingDay model is not in the correct state to run this task"
    end

    target_days = HearingDay.all.order(:id)

    changed = dry_run ? "Would migrate" : "Migrating"
    failed = dry_run ? "Would FAIL to migrate" : "FAILED to migrate"
    message = "#{changed} created and updated by information on #{target_days.count} HearingDays"
    puts message
    day_message = ""

    target_days.each do |day|
      %w[created updated].each do |verb|
        user_id = day["#{verb}_by_id"]
        user_css_id = day["#{verb}_by"]
        id_blank = user_id.blank?
        css_id_present = user_css_id.present?

        if id_blank && css_id_present
          by_user = User.find_by(css_id: user_css_id)
          if by_user.present?
            day.update!("#{verb}_by_id": by_user.id) if !dry_run
            day_message = "#{changed} #{verb}_by user #{by_user.id} (#{by_user.css_id}) for day #{day.id}"
          else
            day_message = "#{failed} #{verb}_by user for day #{day.id}; no user with css_id #{user_css_id}"
          end
        else
          day_message = "#{failed} #{verb}_by user for day #{day.id}"
          day_message = "#{day_message}; #{verb}_by_id already set to #{user_id}" unless id_blank
          day_message = "#{day_message}; #{verb}_by is blank" unless css_id_present
        end

        puts day_message
        Rails.logger.tagged("rake data_migrations:migrate_hearing_day_created_and_updated_by") do
          Rails.logger.info(day_message)
        end
      end
    end
  end
end
