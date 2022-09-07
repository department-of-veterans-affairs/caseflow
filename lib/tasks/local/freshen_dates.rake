# frozen_string_literal: true

require "rainbow"

DEFAULT_DAYS_INCREASE = 60

def update_datetime_column_values(table, column_name, days_increase)
  table.update_all(
    "#{column_name} = (#{column_name} + '#{days_increase} DAY'::INTERVAL)"
  )
end

namespace :db do
  desc "By default adds 60 days to all non-null datetime values" \
    "in the Caseflow. Another amount of days can be supplied with rake db:freshen_dates DAYS=123"
  task freshen_dates: :environment do
    days_increase = DEFAULT_DAYS_INCREASE

    if ENV.key?("DAYS") && !ENV["DAYS"].match(/^(\d)+$/)
      fail ArgumentError, "Please specify a valid number of days."
    else
      days_increase = ENV["DAYS"].to_i
    end

    Rails.application.eager_load!

    CaseflowRecord.descendants.each do |t|
      begin
        t.columns.each do |c|
          if [:datetime, :date].include? c.type
            update_datetime_column_values(t, c.name, days_increase)
          end
        end
      rescue TypeError
        # Some models don't actually correspond to an actual db table and do not have columns
        puts Rainbow("Skipping #{t.name}").yellow
      end
    end

    puts Rainbow("Success!").bg(:green).white + Rainbow(" Your dates are nice and fresh!").green
  end
end
