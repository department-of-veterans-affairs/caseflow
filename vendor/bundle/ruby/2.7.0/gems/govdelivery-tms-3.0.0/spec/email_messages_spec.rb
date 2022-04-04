require 'spec_helper'

describe GovDelivery::TMS::EmailMessages do
  let(:href) {'/messages/email'}
  context 'loading messages' do
    let(:client) {double('client')}
    let(:messages) {[
        { subject: 'hello', body: 'greetings from places', created_at: 'a while ago' },
        { subject: 'hi!', body: 'feel me flow', created_at: 'longer ago' },
        { subject: 'yo', body: 'I am not a robot', created_at: 'even longer ago' }
        ]}
    
    before do
      @messages = GovDelivery::TMS::EmailMessages.new(client, href)
    end
    
    it 'should GET ok' do
      expect(@messages.client).to receive(:get).and_return(double('response', body: messages, status: 200, headers: { 'link' => "</messages/email/page/2>; rel=\"next\",</messages/email/page/11>; rel=\"last\"" }))

      @messages.get
      expect(@messages.collection.length).to eq(3)
      expect(@messages.next.href).to eq('/messages/email/page/2')
      expect(@messages.last.href).to eq('/messages/email/page/11')
    end
    
    it 'should GET ok with parameters' do      
      params = {page_size: 2, sort_by: 'created_by', sort_order: 'foobar'}
      expect(@messages.client).to receive(:get).with(href, params).and_return(double('response', body: messages[1..-1], status: 200, headers: { 'link' => "</messages/email/page/2>; rel=\"next\",</messages/email/page/11>; rel=\"last\"" }))

      @messages.get(params)
      expect(@messages.collection.length).to eq(2)
    end
  end
end
