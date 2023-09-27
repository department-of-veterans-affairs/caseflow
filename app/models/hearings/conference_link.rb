# frozen_string_literal: true

class ConferenceLink < CaseflowRecord
  class NoAliasWithHostPresentError < StandardError; end
  class LinkMismatchError < StandardError; end

  include UpdatedByUserConcern
  include CreatedByUserConcern
  include ConferenceableConcern

  after_create :generate_conference_information

  belongs_to :hearing_day
  belongs_to :created_by, class_name: "User"

  alias_attribute :alias_name, :alias

  private

  def generate_conference_information
    fail NotImplementedError
  end
end



