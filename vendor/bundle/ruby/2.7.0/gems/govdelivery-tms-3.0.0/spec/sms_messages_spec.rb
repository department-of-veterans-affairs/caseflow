require 'spec_helper'

describe GovDelivery::TMS::SmsMessages do
  let(:href) {'/messages/sms'}
  context 'creating a new messages list' do
    let(:client) {double('client')}
    let(:messages) {[
      { short_body: 'hi ho', created_at: 'a while ago' },
      { short_body: 'hello', created_at: 'longer ago' },
      { short_body: 'yo', created_at: 'even longer ago' }
      ]}

    before do
      @messages = GovDelivery::TMS::SmsMessages.new(client, href)
    end
    it 'should GET itself' do
      expect(@messages.client).to receive(:get).and_return(double('response', body: messages, status: 200, headers: { 'link' => "</messages/sms/page/2>; rel=\"next\",</messages/sms/page/11>; rel=\"last\"" }))

      @messages.get
      expect(@messages.collection.length).to eq(3)
      expect(@messages.next.href).to eq('/messages/sms/page/2')
      expect(@messages.last.href).to eq('/messages/sms/page/11')
    end

    it 'should GET ok with parameters' do
      params = {page_size: 2, sort_by: 'created_by', sort_order: 'foobar'}
      expect(@messages.client).to receive(:get).with(href, params).and_return(double('response', body: messages[1..-1], status: 200, headers: { 'link' => "</messages/sms/page/2>; rel=\"next\",</messages/sms/page/11>; rel=\"last\"" }))

      @messages.get(params)
      expect(@messages.collection.length).to eq(2)
    end
  end
end
