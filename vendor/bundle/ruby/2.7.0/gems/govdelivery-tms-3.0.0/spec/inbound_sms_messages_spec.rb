require 'spec_helper'

describe GovDelivery::TMS::InboundSmsMessages do
  context 'creating a new inbound messages list' do
    let(:client) do
      double('client')
    end
    before do
      @messages = GovDelivery::TMS::InboundSmsMessages.new(client, '/inbound_messages')
    end
    it 'should GET itself' do
      body = [{ body: 'HELP', from: '+16125551212', created_at: 'a while ago', to: '(651) 433-6258' }, { body: 'STOP', from: '+16125551212', created_at: 'a while ago', to: '(651) 433-6258' }]
      expect(@messages.client).to receive(:get).and_return(double('response', body: body, status: 200, headers: {}))

      @messages.get
      expect(@messages.collection.length).to eq(2)
    end
  end
end
