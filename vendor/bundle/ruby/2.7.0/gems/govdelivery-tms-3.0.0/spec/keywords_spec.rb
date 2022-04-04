require 'spec_helper'

describe GovDelivery::TMS::Keywords do
  context 'loading keywords' do
    let(:client) do
      double('client')
    end
    before do
      @keywords = GovDelivery::TMS::Keywords.new(client, '/keywords')
    end
    it 'should GET ok' do
      body = [
        { 'name' => 'services', '_links' => { 'self' => '/keywords/1' } },
        { 'name' => 'subscribe', '_links' => { 'self' => '/keywords/2' } }
      ]
      expect(@keywords.client).to receive(:get).and_return(double('response', body: body, status: 200, headers: {}))
      @keywords.get
      expect(@keywords.collection.length).to eq(2)
    end
  end
end
