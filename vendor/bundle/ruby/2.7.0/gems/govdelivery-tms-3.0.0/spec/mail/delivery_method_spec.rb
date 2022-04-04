require 'spec_helper'
require 'mail'
require 'govdelivery/tms/mail/delivery_method'
describe GovDelivery::TMS::Mail::DeliveryMethod do
  subject { GovDelivery::TMS::Mail::DeliveryMethod.new({}) }
  let(:client) { double('GovDelivery::TMS::Client') }
  let(:email_messages) { double('email_messages') }
  let(:tms_message) { double('tms_message', recipients: double(build: GovDelivery::TMS::Recipient.new('href'))) }

  before do
    allow(client).to receive(:email_messages).and_return(email_messages)
    allow(subject).to receive(:client).and_return(client)
  end

  context 'a basic Mail::Message with all options' do
    let(:mail) do
      Mail.new do
        subject 'hi'
        from '"My mom" <my@mom.com>'
        to '"A Nice Fellow" <tyler@sink.govdelivery.com>'
        body '<blink>HI</blink>'
      end
    end

    it 'should get sent' do
      expect(email_messages).to receive(:build).with(
        from_name:  mail[:from].display_names.first,
        from_email: mail.from.first,
        subject:    mail.subject,
        body:       '<blink>HI</blink>'
      ).and_return(tms_message)
      expect(tms_message).to receive(:post!).and_return(true)

      subject.deliver!(mail)
    end
  end

  context 'a basic Mail::Message with minimal options' do
    let(:mail) do
      Mail.new do
        subject 'hi'
        to '"A Nice Fellow" <tyler@sink.govdelivery.com>'
        body '<blink>HI</blink>'
      end
    end

    it 'should get sent' do
      expect(email_messages).to receive(:build).with(
        subject: mail.subject,
        body:    '<blink>HI</blink>'
      ).and_return(tms_message)
      expect(tms_message).to receive(:post!).and_return(true)

      subject.deliver!(mail)
    end
  end

  context 'a multipart Mail::Message' do
    let(:mail) do
      Mail.new do
        subject 'hi'
        from '"My mom" <my@mom.com>'
        to '"A Nice Fellow" <tyler@sink.govdelivery.com>'

        html_part do
          content_type 'text/html; charset=UTF-8'
          body '<blink>HTML</blink>'
        end
      end
    end

    it 'should send' do
      expect(email_messages).to receive(:build).with(
        from_name:  mail[:from].display_names.first,
        from_email: mail.from.first,
        subject:    mail.subject,
        body:       '<blink>HTML</blink>'
      ).and_return(tms_message)
      expect(tms_message).to receive(:post!).and_return(true)

      subject.deliver!(mail)
    end
  end
end
