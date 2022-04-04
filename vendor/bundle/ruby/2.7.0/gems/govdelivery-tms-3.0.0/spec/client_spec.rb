require 'spec_helper'
describe GovDelivery::TMS::Client do
  let(:links) {
    [{'self' => '/'},
     {'horse' => '/horses/new'},
     {'rabbits' => '/rabbits'}]
  }
  context 'a client with a missing rel' do
    before do
      response        = double('response', status: 200,
                               body:               {
                                 'sid'    => 'abcd12345',
                                 '_links' => (links + [{'missing' => '/fail'}])})
      @raw_connection = double('raw_connection', get: response)
      @connection     = allow(GovDelivery::TMS::Connection).to receive(:new).and_return(double('connection', connection: @raw_connection))
    end
    it 'should not blow up or create a relation' do
      @client         = GovDelivery::TMS::Client.new('auth_token', api_root: 'null_url')
      expect{@client.missing}.to raise_error(NoMethodError)
    end
  end
  context 'creating a new client' do
    before do
      response = double('response', status: 200,
                        body:               {
                          'sid'    => 'abcd12345',
                          '_links' => links})
      @raw_connection = double('raw_connection', get: response)
      @connection = allow(GovDelivery::TMS::Connection).to receive(:new).and_return(double('connection', connection: @raw_connection))
      @client = GovDelivery::TMS::Client.new('auth_token', api_root: 'null_url')
    end
    it 'should populate sid' do
      expect(@client.sid).to eq 'abcd12345'
    end
    it 'should set up logging' do
      expect(@client.logger).not_to be_nil
      expect(@client.logger.level).to eq(Logger::INFO)
    end
    it 'should discover endpoints for known services' do
      expect(@client.horse).to be_kind_of(GovDelivery::TMS::Horse)
      expect(@client.rabbits).to be_kind_of(GovDelivery::TMS::Rabbits)
    end
    it 'should handle 4xx responses' do
      allow(@raw_connection).to receive(:get).and_return(double('response', status: 404, body: { 'message' => 'hi' }))
      expect { @client.get('/blargh') }.to raise_error(GovDelivery::TMS::Request::Error)
    end
    it 'should handle 5xx responses' do
      allow(@raw_connection).to receive(:get).and_return(double('response', status: 503, body: { 'message' => 'oops' }))
      expect { @client.get('/blargh') }.to raise_error(GovDelivery::TMS::Request::Error)
    end
    it 'should handle 202 responses' do
      allow(@raw_connection).to receive(:get).and_return(double('response', status: 202, body: { 'message' => 'hi' }))
      expect { @client.get('/blargh') }.to raise_error(GovDelivery::TMS::Request::InProgress)
    end
    it 'should handle all other responses' do
      response = double('response', status: 200, body: { 'message' => 'hi' })
      allow(@raw_connection).to receive(:get).with('/blargh', {params: 'foobar'}).and_return(response)
      expect(@client.get('/blargh', {params: 'foobar'})).to eq(response)
    end

    context 'creating a new client without output' do
      subject { GovDelivery::TMS::Client.new('auth_token', api_root: 'null_url', logger: false) }
      its(:logger) { should be_falsey }
      its(:horse) { should be_kind_of(GovDelivery::TMS::Horse) }
    end

    it 'defaults to the public API URL' do
      expect(GovDelivery::TMS::Client.new('auth_token').api_root).to eq('https://tms.govdelivery.com')
    end
  end
end
