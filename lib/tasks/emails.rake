# frozen_string_literal: true

namespace :emails do
  namespace :virtual_hearings do
    desc "creates sample emails for virtual hearings mailer"
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
          email = VirtualHearingMailer.send(
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
  end
end
