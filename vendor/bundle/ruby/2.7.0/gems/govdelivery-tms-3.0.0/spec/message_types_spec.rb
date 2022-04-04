require 'spec_helper'

describe GovDelivery::TMS::MessageTypes do
  context 'loading message types' do
    let(:client) do
      double('client')
    end
    before do
      @message_types = GovDelivery::TMS::MessageTypes.new(client, '/message_types')
    end

    it 'should GET ok' do
      body = [{ 'code' => 'dcm_unsubscribe',
                'label' => 'Unsubcribe' }]
      expect(@message_types.client).to receive(:get).and_return(double('response', body: body, status: 200, headers: {}))
      @message_types.get
      expect(@message_types.collection.length).to eq(1)
      ct = @message_types.collection.first
      expect(ct.code).to eq('dcm_unsubscribe')
      expect(ct.label).to eq('Unsubcribe')
    end

    it 'should update label if changed' do
      @message_type = GovDelivery::TMS::MessageType.new(client, '/message_types', {code: 'dcm_unsubscribe'})
      response = { code: 'dcm_unsubscribe',
                   label: 'Dcm Unsubscribe' }

      expect(@message_type.client).to receive(:post).and_return(double('response', body: response, status: 200, headers: {}))
      @message_type.post
      expect(@message_type.label).to eql('Dcm Unsubscribe')
    end
  end
end
