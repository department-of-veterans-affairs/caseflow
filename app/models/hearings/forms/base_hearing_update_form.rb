# frozen_string_literal: true

class BaseHearingUpdateForm
  include ActiveModel::Model

  attr_accessor :advance_on_docket_motion_attributes, :bva_poc, :disposition,
                :hearing, :hearing_location_attributes, :hold_open,
                :judge_id, :military_service, :notes, :prepped,
                :representative_name, :room, :scheduled_time_string,
                :summary, :transcript_requested, :virtual_hearing_attributes,
                :witness

  def update
    update_hearing
    update_advance_on_docket_motion unless advance_on_docket_motion_attributes.nil?

    if !virtual_hearing_attributes.nil?
      create_or_update_virtual_hearing
      # TODO Start the job to create the Pexip conference here?
    end
  end

  protected

  def update_hearing; end

  private

  def update_advance_on_docket_motion
    motion = hearing.advance_on_docket_motion || AdvanceOnDocketMotion.find_or_create_by!(
      person_id: advance_on_docket_motion_attributes[:person_id]
    )
    motion.update(advance_on_docket_motion_attributes)
  end

  def create_or_update_virtual_hearing
    created = false

    ActiveRecord::Base.transaction do
      if hearing.request_type == HearingDay::REQUEST_TYPES[:central]
        # Converting from a central hearing to a virtual hearing
        # How to update the request type?
        #   * Get the hearing day,
        #   * Duplicate the hearing day
        #   * Check if a duplicate already exists
        #   * Update the request type
      end

      # TODO: All of this is not atomic :(. Revisit later, since Rails 6 offers an upsert.
      virtual_hearing = VirtualHearing.not_cancelled.find_or_create_by!(hearing: hearing) do |new_virtual_hearing|
        new_virtual_hearing.veteran_email = virtual_hearing_attributes[:veteran_email]
        new_virtual_hearing.judge_email = virtual_hearing_attributes[:judge_email]
        new_virtual_hearing.representative_email = virtual_hearing_attributes[:representative_email]
        created = true
      end

      if !created
        # Don't update these fields if the corresponding email address was not
        # included in the updates.
        emails_sent_updates = {
          veteran_email_sent: !virtual_hearing_attributes.key?(:veteran_email),
          judge_email_sent: !virtual_hearing_attributes.key?(:judge_email),
          representative_email_sent: !virtual_hearing_attributes.key?(:representative_email)
        }.reject { |_k, email_sent| email_sent == true }

        updates = virtual_hearing_attributes.compact.merge(emails_sent_updates)

        virtual_hearing.update(updates)
      end
    end
  end
end
