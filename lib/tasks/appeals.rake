# frozen_string_literal: true

namespace :appeals do
  class NotEnoughArguments < StandardError; end
  class InvalidLocationPassed < StandardError; end
  class VacolsIdsRequired < StandardError; end

  # usage:
  # Move legacy appeals matching the passed VACOLS ids from/to the passed VACOLS locations (dry run)
  #   $ bundle exec rake appeals:change_vacols_location[55,81,12345,23456,34567,45678]
  # Move legacy appeals matching the passed VACOLS ids from/to the passed VACOLS locations (execute)
  #   $ bundle exec rake appeals:change_vacols_location[55,81,false,12345,23456,34567,45678]
  desc "move legacy appeals from one location to another"
  task :change_vacols_location, [:from_location, :to_location, :dry_run] => :environment do |_, args|
    extras = args.extras
    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"
    if dry_run && args.dry_run.present?
      extras.unshift(args.dry_run)
    end

    logger_tag = "rake appeals:change_vacols_location"
    message = "Invoked with: #{args.to_a.join(', ')}"
    message = "(dry run) " + message if dry_run
    Rails.logger.tagged(logger_tag) { Rails.logger.info(message) }
    puts_output = ""

    # make sure the minimum number of arguments were passed
    if args.to_a.length < 3
      fail NotEnoughArguments,
           "requires at least three arguments: a from location, a to location, and at least one VACOLS ID"
    end

    if extras.empty?
      fail NotEnoughArguments,
           "you must pass VACOLS IDs for the appeals you want to change locations for"
    end

    # make sure valid location codes were passed
    [args.from_location, args.to_location].each do |location|
      if LegacyAppeal::LOCATION_CODES.values.exclude? location
        fail InvalidLocationPassed, "#{location} is not a valid VACOLS location"
      end
    end

    if dry_run
      puts_output += "*** DRY RUN\n"
      puts_output += "*** pass 'false' as the third argument to execute\n"
    end

    # step through the passed vacols IDs
    message = "Changing location for #{extras.length} legacy appeals"
    Rails.logger.tagged(logger_tag) { Rails.logger.info(message) } if !dry_run
    puts_output += message + "\n"

    appeals_moved = 0
    extras.each do |vacols_id|
      la = LegacyAppeal.find_by(vacols_id: vacols_id)
      if la.blank?
        message = "No legacy appeal found for vacols_id #{vacols_id}; skipping."
        Rails.logger.tagged(logger_tag) { Rails.logger.info(message) } if !dry_run
        puts_output += message + "\n"
        next
      end

      # make sure the current location is as expected
      current_location = la.location_code
      if current_location != args.from_location
        message = "Legacy appeal with vacols_id #{vacols_id} is in location " \
                  "#{current_location}, not #{args.from_location}; skipping."
        Rails.logger.tagged(logger_tag) { Rails.logger.info(message) } if !dry_run
        puts_output += message + "\n"
        next
      end

      message = "Moving legacy appeal with vacols_id #{vacols_id} from " \
                "location #{args.from_location} to #{args.to_location}."

      if !dry_run
        AppealRepository.update_location!(la, args.to_location)
        Rails.logger.tagged(logger_tag) { Rails.logger.info(message) }
      end

      puts_output += message + "\n"

      appeals_moved += 1
    end

    message = "Moved #{appeals_moved} of #{extras.length} legacy appeals from " \
              "location #{args.from_location} to #{args.to_location}."
    Rails.logger.tagged(logger_tag) { Rails.logger.info(message) } if !dry_run
    puts_output += message + "\n"
    puts puts_output
  end
end
