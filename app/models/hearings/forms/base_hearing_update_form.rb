# frozen_string_literal: true

class BaseHearingUpdateForm
  include ActiveModel::Model

  attr_accessor :bva_poc, :disposition,
                :hearing, :hearing_location_attributes, :hold_open,
                :judge_id, :military_service, :notes, :prepped,
                :representative_name, :room, :scheduled_time_string,
                :summary, :transcript_requested, :virtual_hearing_attributes,
                :witness

  def update
    ActiveRecord::Base.transaction do
      update_hearing

      if !virtual_hearing_attributes.nil?
        create_or_update_virtual_hearing
        # TODO: Start the job to create the Pexip conference here?
      end
    end
  end

  protected

  def update_hearing; end

  private

  def email_sent_flag(attr_key)
    status_changed = virtual_hearing_attributes.key?(:status)

    !(status_changed || virtual_hearing_attributes.key?(attr_key))
  end

  def create_or_update_virtual_hearing
    created = false

    # TODO: All of this is not atomic :(. Revisit later, since Rails 6 offers an upsert.
    virtual_hearing = VirtualHearing.not_cancelled.find_or_create_by!(hearing: hearing) do |new_virtual_hearing|
      new_virtual_hearing.veteran_email = virtual_hearing_attributes[:veteran_email]
      new_virtual_hearing.judge_email = virtual_hearing_attributes[:judge_email]
      new_virtual_hearing.representative_email = virtual_hearing_attributes[:representative_email]
      created = true
    end

    if !created
      # The email sent flag should always be set to false from the API.
      emails_sent_updates = {
        veteran_email_sent: email_sent_flag(:veteran_email),
        judge_email_sent: email_sent_flag(:judge_email),
        representative_email_sent: email_sent_flag(:representative_email)
      }.reject { |_k, email_sent| email_sent == true }

      updates = virtual_hearing_attributes.compact.merge(emails_sent_updates)

      virtual_hearing.update(updates)
    end
  end
end
