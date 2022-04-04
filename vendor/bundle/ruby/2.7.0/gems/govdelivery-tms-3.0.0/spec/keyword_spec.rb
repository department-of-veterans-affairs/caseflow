require 'spec_helper'

describe GovDelivery::TMS::Keyword do
  context 'creating a new keyword' do
    let(:client) do
      double('client')
    end
    before do
      @keyword = GovDelivery::TMS::Keyword.new(client, nil, name: 'LOL', response_text: 'very funny!')
    end
    it 'should initialize with attrs' do
      expect(@keyword.name).to eq('LOL')
      expect(@keyword.response_text).to eq('very funny!')
    end
    it 'should post successfully' do
      response = { name: 'lol' }
      expect(@keyword.client).to receive('post').with(@keyword).and_return(double('response', status: 201, body: response))
      @keyword.post
      expect(@keyword.name).to eq('lol')
      expect(@keyword.response_text).to eq('very funny!')
    end
    it 'should handle errors' do
      response = { 'errors' => { name: "can't be nil" } }
      expect(@keyword.client).to receive('post').with(@keyword).and_return(double('response', status: 422, body: response))
      @keyword.post
      expect(@keyword.name).to eq('LOL')
      expect(@keyword.response_text).to eq('very funny!')
      expect(@keyword.errors).to eq(name: "can't be nil")
    end
  end

  context 'an existing keyword' do
    let(:client) do
      double('client')
    end
    before do
      # blank hash prevents the client from doing a GET in the initialize method
      @keyword = GovDelivery::TMS::Keyword.new(client, '/keywords/99', {})
    end
    it 'should GET cleanly' do
      response = { name: 'FOO', response_text: 'hello' }
      expect(@keyword.client).to receive('get').with(@keyword.href, {}).and_return(double('response', status: 200, body: response))
      @keyword.get
      expect(@keyword.name).to eq('FOO')
      expect(@keyword.response_text).to eq('hello')
    end
    it 'should PUT cleanly' do
      @keyword.name = 'GOVLIE'
      response  = { name: 'govlie', response_text: nil }
      expect(@keyword.client).to receive('put').with(@keyword).and_return(double('response', status: 200, body: response))
      @keyword.put
      expect(@keyword.name).to eq('govlie')
      expect(@keyword.response_text).to be_nil
    end
    it 'should DELETE cleanly' do
      expect(@keyword.client).to receive('delete').with(@keyword.href).and_return(double('response', status: 200, body: ''))
      @keyword.delete
    end
  end
end
