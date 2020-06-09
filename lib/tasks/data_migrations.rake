# frozen_string_literal: true

# Rake tasks for one-time migrations
namespace :data_migrations do
  class VirtualHearingModelNotInCorrectState < StandardError; end

  # description:
  #   This task is built for a one-time migration of veteran_email and veteran_email_sent data to
  #   appellant_email and appellant_email_sent respectively of VirtualHearing objects. It expects
  #   VirtualHearing objects to have appellant_email and appellant_email_sent which will be populated by
  #   veteran_email and veteran_email_sent column data. Both veteran_email_sent and appellant_email_sent
  #   are fields which are validated not be nil so we don't do any validation during migration.
  #
  # usage:
  #   Migrate veteran_email and veteran_email_sent (dry run)
  #     $ bundle exec rake data_migrations:migrate_virtual_hearings_veteran_email_and_veteran_email_sent
  #   Migrate veteran_email and veteran_email_sent (execute)
  #     $ bundle exec rake data_migrations:migrate_hearing_day_created_and_updated_by[false]"
  desc "migrate the veteran_email and veteran_email_sent data into appellant_email and
    appellant_email_sent"
  task :migrate_virtual_hearings_veteran_email_and_veteran_email_sent, [:dry_run] => :environment do |_, args|
    Rails.logger.tagged("rake data_migrations:migrate_virtual_hearings_veteran_email_and_veteran_email_sent") do
      Rails.logger.info("Invoked with: #{args.to_a.join(', ')}")
    end

    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"

    if dry_run
      puts "*** DRY RUN"
      puts "*** pass 'false' as the first argument to execute"

      Rails.logger.info("Starting dry run")
    else
      Rails.logger.info("Starting migration")
    end

    # make sure the VirtualHearing model is in the correct state
    required_column_names = %w[veteran_email veteran_email_sent appellant_email appellant_email_sent]
    has_required_columns = (VirtualHearing.column_names & required_column_names).size == required_column_names.size

    has_no_associations = VirtualHearing.reflect_on_association(:veteran_email).blank? &&
                          VirtualHearing.reflect_on_association(:veteran_email_sent).blank? &&
                          VirtualHearing.reflect_on_association(:appellant_email).blank? &&
                          VirtualHearing.reflect_on_association(:appellant_email_sent).blank?

    unless has_required_columns && has_no_associations
      fail VirtualHearingModelNotInCorrectState, "The VirtualHearing model is not in the correct state to run this task"
    end

    target_virtual_hearings = VirtualHearing.all

    changed = dry_run ? "Would migrate" : "Migrating"

    message = "#{changed} veteran_email and veteran_email_sent data for " \
      "#{target_virtual_hearings.count} VirtualHearing objects"
    puts message

    target_virtual_hearings.each do |virtual_hearing|
      veteran_email = virtual_hearing.veteran_email
      veteran_email_sent = virtual_hearing.veteran_email_sent

      if !dry_run
        virtual_hearing.update!(appellant_email: veteran_email, appellant_email_sent: veteran_email_sent)
      end

      message = "#{changed} (veteran_email: #{veteran_email}) to appellant_email " \
          "and (veteran_email_sent: #{veteran_email_sent}) to appellant_email_sent " \
          "for virtual_hearing (#{virtual_hearing.id})"

      puts message
      Rails.logger.tagged("rake data_migrations:migrate_virtual_hearings_veteran_email_and_veteran_email_sent") do
        Rails.logger.info(message)
      end
    end
  end
end
