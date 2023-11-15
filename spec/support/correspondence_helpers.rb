# frozen_string_literal: true

module CorrespondenceHelpers
  def visit_intake_form_with_correspondence_load
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    54.times { create(:correspondence, veteran_id: veteran.id, uuid: SecureRandom.uuid, va_date_of_receipt: Time.local(2023, 1, 1) ) }
    allow_any_instance_of(CorrespondenceController).to receive(:correspondence_load).and_return(Correspondence.all)

    visit "/queue/correspondence/#{Correspondence.first.uuid}/intake"
  end

  def visit_intake_form
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    uuid = SecureRandom.uuid
    visit "/queue/correspondence/#{uuid}/intake"
  end

  def associate_with_prior_mail_radio_options
    radio_options = page.all(".cf-form-radio-option")
    { yes: radio_options[0], no: radio_options[1] }
  end
end
