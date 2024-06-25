# frozen_string_literal: true

class ConferenceLink < CaseflowRecord
  class NoAliasWithHostPresentError < StandardError; end
  class LinkMismatchError < StandardError; end

  acts_as_paranoid

  include UpdatedByUserConcern
  include CreatedByUserConcern
  include ConferenceableConcern

  belongs_to :hearing, polymorphic: true

  after_create :generate_conference_information

  belongs_to :hearing_day
  belongs_to :created_by, class_name: "User"

  alias_attribute :alias_name, :alias

  # Purpose: updates the conf_link and then soft_deletes them.
  #
  # Params: None
  #
  # Return: None
  def soft_removal_of_link
    update!(update_conf_links)
    destroy
  end

  private

  # Purpose: Updates conference_link attributes when passed into the 'update!' method.
  #
  # Params: None
  #
  # Return: Hash that will update the conference_link
  def update_conf_links
    {
      conference_deleted: true,
      updated_by_id: RequestStore[:current_user] = User.system_user,
      updated_at: Time.zone.now
    }
  end

  def generate_conference_information
    fail NotImplementedError
  end
end
