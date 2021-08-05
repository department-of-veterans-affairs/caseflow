# frozen_string_literal: true

namespace :emails do
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
          :convert_to_virtual_confirmation,
          :convert_from_virtual_confirmation,
          :updated_time_confirmation,
          :cancellation,
          :reminder
        ].each do |func|
          email = HearingMailer.send(
            func,
            email_recipient: recipient,
            virtual_hearing: hearing.virtual_hearing
          )
          email_body = email.html_part&.decoded || email.body
          email_subject = email.subject

          next if email_body.blank?

          output_file = Rails.root.join("tmp", "#{func}_#{recipient.title}.html")

          File.write(output_file, email_subject, mode: "w")
          File.write(output_file, email_body, mode: "a")
        end
      end
    end

    desc "creates reminder emails for hearings mailer"
    task :reminder, [:request_type] => :environment do |_task, args|
      include FactoryBot::Syntax::Methods
      args.with_defaults(request_type: :virtual)

      hearing = build(
        :hearing,
        virtual_hearing: build(:virtual_hearing, :initialized)
      )

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
          hearing: (args.request_type != :virtual) ? hearing : nil,
          email_recipient: recipient,
          virtual_hearing: hearing.virtual_hearing
        )
        email_body = email.html_part&.decoded || email.body
        email_subject = email.subject

        next if email_body.blank?

        output_file = Rails.root.join("tmp", "reminder_#{recipient.title}.html")

        File.write(output_file, email_subject, mode: "w")
        File.write(output_file, email_body, mode: "a")
      end
    end
  end
end
