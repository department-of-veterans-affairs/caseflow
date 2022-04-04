require 'spec_helper'

describe GovDelivery::TMS::EmailMessage do
  context 'creating a new message' do
    let(:client) do
      double('client')
    end
    before do
      @message = GovDelivery::TMS::EmailMessage.new(client, '/messages/email',         body:       '12345678',
                                                                                       subject:    'blah',
                                                                                       created_at: 'BAAAAAD',
                                                                                       from_email: 'eric@evotest.govdelivery.com',
                                                                                       errors_to:  'errors@evotest.govdelivery.com',
                                                                                       reply_to:   'replyto@evotest.govdelivery.com')
    end
    it 'should not render readonly attrs in json hash' do
      expect(@message.to_json[:body]).to eq('12345678')
      expect(@message.to_json[:created_at]).to eq(nil)
    end
    it 'should initialize with attrs and collections' do
      expect(@message.body).to eq('12345678')
      expect(@message.subject).to eq('blah')
      expect(@message.from_email).to eq('eric@evotest.govdelivery.com')
      expect(@message.reply_to).to eq('replyto@evotest.govdelivery.com')
      expect(@message.errors_to).to eq('errors@evotest.govdelivery.com')
      expect(@message.recipients.class).to eq(GovDelivery::TMS::EmailRecipients)
    end
    it 'should post successfully' do
      response = {
        body:       'processed',
        subject:    'blah',
        from_email: 'eric@evotest.govdelivery.com',
        errors_to:  'errors@evotest.govdelivery.com',
        reply_to:   'replyto@evotest.govdelivery.com',
        recipients: [{ email: 'billy@evotest.govdelivery.com' }],
        failed: [{ email: 'billy@evotest.govdelivery.com' }],
        sent: [{ email: 'billy@evotest.govdelivery.com' }],
        created_at: 'time'
      }
      expect(@message.client).to receive('post').with(@message).and_return(double('response', status: 201, body: response))
      @message.post
      expect(@message.body).to eq('processed')
      expect(@message.created_at).to eq('time')
      expect(@message.from_email).to eq('eric@evotest.govdelivery.com')
      expect(@message.reply_to).to eq('replyto@evotest.govdelivery.com')
      expect(@message.errors_to).to eq('errors@evotest.govdelivery.com')
      expect(@message.recipients.class).to eq(GovDelivery::TMS::EmailRecipients)
      expect(@message.recipients.collection.first.class).to eq(GovDelivery::TMS::EmailRecipient)
      expect(@message.sent.class).to eq(GovDelivery::TMS::EmailRecipients)
      expect(@message.sent.collection.first.class).to eq(GovDelivery::TMS::EmailRecipient)
      expect(@message.failed.class).to eq(GovDelivery::TMS::EmailRecipients)
      expect(@message.failed.collection.first.class).to eq(GovDelivery::TMS::EmailRecipient)
    end
    it 'should handle errors' do
      response = { 'errors' => { body: "can't be nil" } }
      expect(@message.client).to receive('post').with(@message).and_return(double('response', status: 422, body: response))
      @message.post
      expect(@message.body).to eq('12345678')
      expect(@message.errors).to eq(body: "can't be nil")
    end

    it 'should handle 401 errors' do
      expect(@message.client).to receive('post').with(@message).and_return(double('response', status: 401))
      expect { @message.post }.to raise_error(StandardError, '401 Not Authorized')
    end

    it 'should handle 404 errors' do
      expect(@message.client).to receive('post').with(@message).and_return(double('response', status: 404))
      expect { @message.post }.to raise_error(StandardError, "Can't POST to /messages/email")
    end
  end

  context 'an existing message' do
    let(:client) do
      double('client')
    end
    before do
      # blank hash prevents the client from doing a GET in the initialize method
      @message = GovDelivery::TMS::EmailMessage.new(client, '/messages/99', {})
    end
    it 'should GET cleanly' do
      response = { 'body'       => 'processed',
                   'subject'    => 'hey',
                   'from_email' => 'eric@evotest.govdelivery.com',
                   'errors_to'  => 'errors@evotest.govdelivery.com',
                   'reply_to'   => 'replyto@evotest.govdelivery.com',
                   'recipients' => [{ email: 'billy@evotest.govdelivery.com' }],
                   'created_at' => 'time',
                   'message_type_code' => 'salutations',
                   '_links'     => { 'self' => '/messages/email/new-template',
                                     'message_type' => '/message_type/abc',
                                     'email_template' => '/templates/email/new-template' }
                  }
      expect(@message.client).to receive('get').with(@message.href, {}).and_return(double('response', status: 200, body: response))
      @message.get
      expect(@message.body).to eq('processed')
      expect(@message.subject).to eq('hey')
      expect(@message.from_email).to eq('eric@evotest.govdelivery.com')
      expect(@message.reply_to).to eq('replyto@evotest.govdelivery.com')
      expect(@message.errors_to).to eq('errors@evotest.govdelivery.com')
      expect(@message.created_at).to eq('time')
      expect(@message.message_type_code).to eq('salutations')
      expect(@message.email_template).to be_a(GovDelivery::TMS::EmailTemplate)
      expect(@message.message_type).to be_a(GovDelivery::TMS::MessageType)
    end
  end
end
