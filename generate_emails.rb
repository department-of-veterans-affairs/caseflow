# Load the Rails environment
ENV['RAILS_ENV'] ||= 'development'
require File.expand_path('../config/environment', __FILE__)

# Require necessary libraries
require 'fileutils'
require 'mail'

# Define the write_output_to_file method
def write_output_to_file(file_name, email, from_email, to_email)
  body = email.html_part&.decoded || email.body
  subject = email.subject

  return if body.blank?

  email_output_dir = "tmp/hearing_emails/"
  FileUtils.mkpath(email_output_dir)
  output_file = File.join(email_output_dir, file_name)
  File.write(output_file, subject, mode: "w")
  File.write(output_file, body, mode: "a")

  # Send the email to MailDev with the specified "from" and "to" addresses
  send_email_to_maildev(email, from_email, to_email)
end

# Define the send_email_to_maildev method with "from" and "to" parameters
def send_email_to_maildev(email, from_email, to_email)
  Mail.defaults { delivery_method :smtp, address: 'localhost', port: 1025 }
  Mail.deliver do
    from    from_email
    to      to_email
    subject email.subject
    body    email.body.to_s
  end
end

# Define the generate_and_send_emails method
def generate_and_send_emails
  # Create a sample HearingEmailRecipient object
  recipient = HearingEmailRecipient.new(email_address: 'recipient@example.com')  # Replace with the recipient's email address

  # Get the "from" email address (sender's email address)
  from_email = 'your@example.com'  

  # Get the "to" email address (recipient's email address)
  to_email = recipient.email_address

  # Create a sample confirmation email
  hearing = FactoryBot.build(:hearing, virtual_hearing: FactoryBot.build(:virtual_hearing, :initialized))
  appellant_recipient = FactoryBot.build(:hearing_email_recipient, :appellant_hearing_email_recipient, hearing: hearing)

  recipient_info = EmailRecipientInfo.new(
    name: "Appellant",
    hearing_email_recipient: appellant_recipient,
    title: HearingEmailRecipient::RECIPIENT_TITLES[:appellant]
  )

  # Generate a confirmation email
  confirmation_email = HearingMailer.confirmation(
    email_recipient_info: recipient_info,
    virtual_hearing: hearing.virtual_hearing
  )

  # Define the file name and save the email to the "tmp/hearing_emails" directory
  file_name = "confirmation_appellant.html"
  write_output_to_file(file_name, confirmation_email, from_email, to_email)
end

# Call the generate_and_send_emails method
generate_and_send_emails
