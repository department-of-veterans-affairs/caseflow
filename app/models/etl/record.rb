# frozen_string_literal: true

# abstract base class for all ETL:: models

# "original" == Caseflow db record
# "target" == ETL db record
#
# Note about schema Rails automatic meta columns:
#  * if the table is a 1:1 mirror:
#    * the "id" is the same in original and target
#    * the "created_at" and "updated_at" are the same on original and target
#  * if the table is transformed in any way:
#    * the "id" of the original is mapped to ":original_id" (e.g. appeal_id)
#    * the "created_at" refers to the ETL record, the ":original_created_at" is the origin timestamp.
#    * the "updated_at" refers to the ETL record, the ":original_updated_at" is the origin timestamp.

class ETL::Record < ApplicationRecord
  self.abstract_class = true
  establish_connection :"etl_#{Rails.env}"

  class << self
    def sync_with_original(original)
      target = find_by_primary_key(original) || new
      merge_original_attributes_to_target(original, target)
    end

    # the column on this class that refers to the origin class primary key
    # the default assumption is that the 2 classes share a primary key name (e.g. "id")
    def origin_primary_key
      primary_key
    end

    def slack_url
      ENV["SLACK_DISPATCH_ALERT_URL"]
    end

    def slack_service
      @slack_service ||= SlackService.new(url: slack_url)
    end

    # :reek:LongParameterList
    def check_equal(record_id, attribute, expected, actual)
      return if expected == actual

      msg = "#{name} #{record_id}: Expected #{attribute} to equal #{expected} but got #{actual}"
      slack_service.send_notification(msg, self.name, "#appeals-data-workgroup")
    end

    private

    def org_cache(org_id)
      return if org_id.blank?

      @org_cache ||= {}
      @org_cache[org_id] ||= Organization.find(org_id)
    end

    def user_cache(user_id)
      return if user_id.blank?

      @user_cache ||= {}
      @user_cache[user_id] ||= User.find(user_id)
    end

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes
      target
    end

    def find_by_primary_key(original)
      pk = original[original.class.primary_key]
      find_by(origin_primary_key => pk)
    end
  end
end
