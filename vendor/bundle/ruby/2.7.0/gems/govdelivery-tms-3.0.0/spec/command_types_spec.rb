require 'spec_helper'

describe GovDelivery::TMS::CommandTypes do
  context 'loading command types' do
    let(:client) do
      double('client')
    end
    before do
      @command_types = GovDelivery::TMS::CommandTypes.new(client, '/command_types')
    end
    it 'should GET ok' do
      body = [{ 'name' => 'dcm_unsubscribe',
                'string_fields' => [],
                'array_fields' => ['dcm_account_codes'] },
              { 'name' => 'dcm_subscribe',
                'string_fields' => ['dcm_account_code'],
                'array_fields' => ['dcm_topic_codes'] },
              { 'name' => 'forward',
                'string_fields' => %w(http_method username password url),
                'array_fields' => [] }]
      expect(@command_types.client).to receive(:get).and_return(double('response', body: body, status: 200, headers: {}))
      @command_types.get
      expect(@command_types.collection.length).to eq(3)
      ct = @command_types.collection.find { |c| c.name == 'dcm_subscribe' }
      expect(ct.array_fields).to eq(['dcm_topic_codes'])
      expect(ct.string_fields).to eq(['dcm_account_code'])
    end
  end
end
