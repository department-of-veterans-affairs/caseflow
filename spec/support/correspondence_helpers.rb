# frozen_string_literal: true

module CorrespondenceHelpers
  def visit_intake_form_with_correspondence_load
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    54.times do
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
    end
    allow_any_instance_of(CorrespondenceController).to receive(:correspondence_load).and_return(Correspondence.all)

    visit "/queue/correspondence/#{Correspondence.first.uuid}/intake"
  end

  def visit_intake_form
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    uuid = SecureRandom.uuid
    visit "/queue/correspondence/#{uuid}/intake"
  end

  def visit_intake_form_step_2_with_appeals
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    13.times { create(:appeal, veteran_file_number: veteran.file_number) }
    3.times do
      create(
        :correspondence,
        veteran_id: veteran.id,
        uuid: SecureRandom.uuid,
        va_date_of_receipt: Time.zone.local(2023, 1, 1)
      )
    end
    allow_any_instance_of(CorrespondenceController).to receive(:correspondence_load).and_return(Correspondence.all)

    visit "/queue/correspondence/#{Correspondence.first.uuid}/intake"

    click_button("Continue")
  end

  def visit_intake_form_step_3_with_tasks_unrelated
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    create(
      :correspondence,
      veteran_id: veteran.id,
      uuid: SecureRandom.uuid,
      va_date_of_receipt: Time.zone.local(2023, 1, 1)
    )
    visit "/queue/correspondence/#{Correspondence.first.uuid}/intake"

    click_button("Continue")
    click_button("+ Add tasks")
    all("#reactSelectContainer")[0].click
    find_by_id("react-select-2-option-0").click
    find_by_id("content", visible: :all).fill_in with: "Correspondence test text"
    click_button("Continue")
  end

  def associate_with_prior_mail_radio_options
    radio_options = page.all(".cf-form-radio-option")
    { yes: radio_options[0], no: radio_options[1] }
  end

  def existing_appeal_radio_options
    radio_options = page.all(".cf-form-radio-option")
    { yes: radio_options[0], no: radio_options[1] }
  end

  def active_evidence_submissions_tasks
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    veteran = create(:veteran, last_name: "Smith", file_number: "12345678")
    create(:correspondence, veteran_id: veteran.id, uuid: SecureRandom.uuid, va_date_of_receipt: Time.local(2023, 1, 1))
    2.times do
      appeal = create(:appeal, veteran_file_number: veteran.file_number)

        InitialTasksFactory.new(appeal).create_root_and_sub_tasks!
        EvidenceSubmissionWindowTask.create!(
          appeal: appeal,
          parent: appeal.root_task,
          assigned_to: MailTeam.singleton
        )
    end
    visit "/queue/correspondence/#{Correspondence.first.uuid}/intake"
    click_button("Continue")
  end


end
