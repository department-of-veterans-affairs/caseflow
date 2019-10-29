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
    create_virtual_hearing unless virtual_hearing_attributes.nil?
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

  def create_virtual_hearing
    created = false

    VirtualHearing.where.not(status: :cancelled).find_or_create_by!(hearing: hearing) do |virtual_hearing|
      virtual_hearing.veteran_email = virtual_hearing_attributes[:veteran_email]
      virtual_hearing.judge_email = virtual_hearing_attributes[:judge_email]
      virtual_hearing.representative_email = virtual_hearing_attributes[:representative_email]
      created = true
    end

    fail ActiveRecord::RecordNotUnique if !created
  end
end
