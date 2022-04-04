require 'spec_helper'

describe GovDelivery::TMS::SmsMessage do
  context 'creating a new message' do
    let(:client) do
      double('client')
    end
    before do
      @message = GovDelivery::TMS::SmsMessage.new(client, nil, body: '12345678', created_at: 'BAAAAAD')
    end
    it 'should not render readonly attrs in json hash' do
      expect(@message.to_json[:body]).to eq('12345678')
      expect(@message.to_json[:created_at]).to eq(nil)
    end
    it 'should initialize with attrs and collections' do
      expect(@message.body).to eq('12345678')
      expect(@message.recipients.class).to eq(GovDelivery::TMS::Recipients)
    end
    it 'should post successfully' do
      response = { body: 'processed',
                   recipients: [{ phone: '22345678' }],
                   failed: [{ phone: '22345678' }],
                   sent: [{ phone: '22345678' }],
                   created_at: 'time' }
      expect(@message.client).to receive('post').with(@message).and_return(double('response', status: 201, body: response))
      @message.post
      expect(@message.body).to eq('processed')
      expect(@message.created_at).to eq('time')
      expect(@message.recipients.class).to eq(GovDelivery::TMS::Recipients)
      expect(@message.recipients.collection.first.class).to eq(GovDelivery::TMS::Recipient)
      expect(@message.sent.class).to eq(GovDelivery::TMS::Recipients)
      expect(@message.sent.collection.first.class).to eq(GovDelivery::TMS::Recipient)
      expect(@message.failed.class).to eq(GovDelivery::TMS::Recipients)
      expect(@message.failed.collection.first.class).to eq(GovDelivery::TMS::Recipient)
    end
    it 'should handle errors' do
      response = { 'errors' => { body: "can't be nil" } }
      expect(@message.client).to receive('post').with(@message).and_return(double('response', status: 422, body: response))
      @message.post
      expect(@message.body).to eq('12345678')
      expect(@message.errors).to eq(body: "can't be nil")
    end
  end

  context 'an existing message' do
    let(:client) do
      double('client')
    end
    before do
      # blank hash prevents the client from doing a GET in the initialize method
      @message = GovDelivery::TMS::SmsMessage.new(client, '/messages/99', {})
    end
    it 'should GET cleanly' do
      response = { body: 'processed', recipients: [{ phone: '22345678' }], created_at: 'time' }
      expect(@message.client).to receive('get').with(@message.href, {}).and_return(double('response', status: 200, body: response))
      @message.get
      expect(@message.body).to eq('processed')
      expect(@message.created_at).to eq('time')
    end
  end
end
