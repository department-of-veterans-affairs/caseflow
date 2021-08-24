# frozen_string_literal: true

namespace :emails do
  # This function sends the email to a file in caseflow/tmp
  def write_output_to_file(file_name, email)
    body = email.html_part&.decoded || email.body
    subject = email.subject

    return if body.blank?

    output_file = Rails.root.join("tmp", file_name)
    File.write(output_file, subject, mode: "w")
    File.write(output_file, body, mode: "a")
  end

  namespace :hearings do
    desc "creates sample emails for hearings mailer"
    task sample: :environment do
      include FactoryBot::Syntax::Methods

      # Create a fake Hearing that *is not* saved to the database.
      hearing = build(
        :hearing,
        virtual_hearing: build(:virtual_hearing, :initialized)
      )

      appellant_recipient = build(
        :hearing_email_recipient,
        :appellant_hearing_email_recipient,
        hearing: hearing
      )

      representative_recipient = build(
        :hearing_email_recipient,
        :representative_hearing_email_recipient,
        hearing: hearing
      )

      judge_recipient = build(
        :hearing_email_recipient,
        :judge_hearing_email_recipient,
        hearing: hearing
      )

      recipients = [
        EmailRecipientInfo.new(
          name: "Appellant", # Can't create a fake appellant without saving to the DB
          hearing_email_recipient: appellant_recipient,
          title: HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
        ),
        EmailRecipientInfo.new(
          name: hearing.judge.full_name,
          hearing_email_recipient: judge_recipient,
          title: HearingEmailRecipient::RECIPIENT_TITLES[:judge]
        ),
        EmailRecipientInfo.new(
          name: "Power of Attorney", # POA name is too complicated to fake for this
          hearing_email_recipient: representative_recipient,
          title: HearingEmailRecipient::RECIPIENT_TITLES[:representative]
        )
      ]

      recipients.each do |recipient|
        [
          :confirmation,
          :updated_time_confirmation,
          :cancellation
        ].each do |func|
          email = HearingMailer.send(
            func,
            email_recipient: recipient,
            virtual_hearing: hearing.virtual_hearing
          )
          file_name = "#{func}_#{recipient.title}.html"
          write_output_to_file(file_name, email)
        end
      end
    end

    desc "creates reminder emails for hearings mailer"
    task :reminder, [:request_type, :reminder_type] => :environment do |_task, args|
      include FactoryBot::Syntax::Methods
      args.with_defaults(request_type: :virtual)
      args.with_defaults(reminder_type: Hearings::ReminderService::TWO_DAY_REMINDER)

      if args.request_type.to_sym == :video
        hearing_day = build(
          :hearing_day,
          :video,
          created_by: User.last,
          updated_by: User.last,
          request_type: HearingDay::REQUEST_TYPES[args.request_type.to_sym]
        )

        hearing = build(
          :hearing,
          regional_office: "RO15",
          hearing_day: hearing_day
        )
      elsif args.request_type.to_sym == :central
        hearing_day = build(
          :hearing_day,
          created_by: User.last,
          updated_by: User.last,
          request_type: HearingDay::REQUEST_TYPES[args.request_type.to_sym]
        )

        hearing = build(
          :hearing,
          hearing_day: hearing_day
        )
      elsif args.request_type.to_sym == :virtual
        hearing = build(
          :hearing,
          judge: User.last,
          adding_user: User.last
        )
        virtual_hearing = build(
          :virtual_hearing,
          :initialized,
          hearing: hearing
        )
      end

      build(
        :hearing_email_recipient,
        :appellant_hearing_email_recipient,
        hearing: hearing
      )

      build(
        :hearing_email_recipient,
        :representative_hearing_email_recipient,
        hearing: hearing
      )

      build(
        :hearing_email_recipient,
        :judge_hearing_email_recipient,
        hearing: hearing
      )

      recipients = [
        EmailRecipientInfo.new(
          name: "Appellant Full Name", # Can't create a fake appellant without saving to the DB
          hearing_email_recipient: hearing.appellant_recipient,
          title: HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
        ),
        EmailRecipientInfo.new(
          name: hearing.judge.full_name,
          hearing_email_recipient: hearing.judge_recipient,
          title: HearingEmailRecipient::RECIPIENT_TITLES[:judge]
        ),
        EmailRecipientInfo.new(
          name: "Power of Attorney", # POA name is too complicated to fake for this
          hearing_email_recipient: hearing.representative_recipient,
          title: HearingEmailRecipient::RECIPIENT_TITLES[:representative]
        )
      ]

      recipients.each do |recipient|
        email = HearingMailer.send(
          :reminder,
          day_type: args.reminder_type.to_sym,
          hearing: (args.request_type != :virtual) ? hearing : nil,
          email_recipient: recipient,
          virtual_hearing: virtual_hearing
        )
        file_name = "reminder_#{recipient.title}.html"
        write_output_to_file(file_name, email)
      end
    end

    desc "creates reminder emails for hearings mailer"
    # :environment is required for FactoryBot build/create to work
    task status_emails: :environment do
      # Build the objects for test
      include FactoryBot::Syntax::Methods
      sent_hearing_email_event = build(:sent_hearing_email_event)

      # Fill in the template using the test objects
      mailer_function_name = :notification
      email = HearingEmailStatusMailer.send(
        mailer_function_name,
        sent_hearing_email_event: sent_hearing_email_event
      )

      # Write the email html to a file in tmp
      file_name = "#{mailer_function_name}_#{sent_hearing_email_event.recipient_role}.html"
      write_output_to_file(file_name, email)
    end
  end
end
