require 'spec_helper'

describe GovDelivery::TMS::FromAddress do
  context 'creating a list of from addresses' do
    let(:client) do
      double('client')
    end
    before do
      @fromaddresses = GovDelivery::TMS::FromAddresses.new(client, '/from_addresses')
    end

    it 'should be able to get a list of email templates' do
      response = [{
        'from_email'      => 'something@evotest.govdelivery.com',
        'from_name'       => 'Something',
        'reply_to_email'  => 'something@evotest.govdelivery.com',
        'bounce_email'    => 'something@evotest.govdelivery.com',
        'is_default'      => true,
        'id'              => '1',
        'created_at'      => 'sometime',
        '_links'          => { 'self' => '/from_addresses/1' }
      }]

      expect(@fromaddresses.client).to receive('get').with('/from_addresses',{}).and_return(double('/from_addresses', status: 200, body: response, headers: {}))
      addresses = @fromaddresses.get
      expect(addresses.collection.length).to eq(1)
      expect(addresses.collection.first.class).to eq(GovDelivery::TMS::FromAddress)
      expect(addresses.collection.first.from_email).to eq('something@evotest.govdelivery.com')
      expect(addresses.collection.first.from_name).to eq('Something')
    end
  end

  context 'handling errors' do
    let(:client) do
      double('client')
    end
    before do
      @fromaddress = GovDelivery::TMS::FromAddress.new(client, '/from_addresses/1')
    end

    it 'should handle errors' do
      response = { 'errors' => { from_email: "can't be nil" } }
      expect(@fromaddress.client).to receive('post').with(@fromaddress).and_return(double('response', status: 422, body: response))
      @fromaddress.post
      expect(@fromaddress.errors).to eq(from_email: "can't be nil")
    end

    it 'should handle 401 errors' do
      expect(@fromaddress.client).to receive('post').with(@fromaddress).and_return(double('response', status: 401))
      expect { @fromaddress.post }.to raise_error('401 Not Authorized')
    end

    it 'should handle 404 errors' do
      expect(@fromaddress.client).to receive('post').with(@fromaddress).and_return(double('response', status: 404))
      expect { @fromaddress.post }.to raise_error("Can't POST to /from_addresses/1")
    end
  end
end
