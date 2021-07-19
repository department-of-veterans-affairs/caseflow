# frozen_string_literal: true

namespace :emails do
  namespace :virtual_hearings do
    desc "creates sample emails for hearings mailer"
    task sample: :environment do
      include FactoryBot::Syntax::Methods

      # Create a fake Hearing that *is not* saved to the database.
      hearing = build(
        :hearing,
        virtual_hearing: build(:virtual_hearing, :initialized)
      )

      recipients = [
        MailRecipient.new(
          name: "Appellant", # Can't create a fake appellant without saving to the DB
          email: hearing.virtual_hearing.appellant_email,
          title: MailRecipient::RECIPIENT_TITLES[:appellant]
        ),
        MailRecipient.new(
          name: hearing.judge.full_name,
          email: hearing.virtual_hearing.judge_email,
          title: MailRecipient::RECIPIENT_TITLES[:judge]
        ),
        MailRecipient.new(
          name: "Power of Attorney", # POA name is too complicated to fake for this
          email: hearing.virtual_hearing.representative_email,
          title: MailRecipient::RECIPIENT_TITLES[:representative]
        )
      ]

      recipients.each do |recipient|
        [
          :confirmation,
          :updated_time_confirmation,
          :cancellation,
          :reminder
        ].each do |func|
          email = HearingMailer.send(
            func,
            mail_recipient: recipient,
            virtual_hearing: hearing.virtual_hearing
          )
          email_body = email.html_part&.decoded || email.body

          next if email_body.blank?

          output_file = Rails.root.join("tmp", "#{func}_#{recipient.title}.html")

          File.write(output_file, email_body, mode: "w")
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

      recipients = [
        MailRecipient.new(
          name: "Appellant Full Name", # Can't create a fake appellant without saving to the DB
          email: "appellant@test.va.gov",
          title: MailRecipient::RECIPIENT_TITLES[:appellant]
        ),
        MailRecipient.new(
          name: hearing.judge.full_name,
          email: "judge@test.va.gov",
          title: MailRecipient::RECIPIENT_TITLES[:judge]
        ),
        MailRecipient.new(
          name: "Power of Attorney", # POA name is too complicated to fake for this
          email: "poa@test.va.gov",
          title: MailRecipient::RECIPIENT_TITLES[:representative]
        )
      ]

      recipients.each do |recipient|
        email = HearingMailer.send(
          :reminder,
          hearing: (args.request_type != :virtual) ? hearing : nil,
          mail_recipient: recipient,
          virtual_hearing: hearing.virtual_hearing
        )
        email_body = email.html_part&.decoded || email.body

        next if email_body.blank?

        output_file = Rails.root.join("tmp", "reminder_#{recipient.title}.html")

        File.write(output_file, email_body, mode: "w")
      end
    end
  end
end
