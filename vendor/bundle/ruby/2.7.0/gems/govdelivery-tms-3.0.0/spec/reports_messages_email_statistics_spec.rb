require 'spec_helper'

describe GovDelivery::TMS::ReportsMessagesEmailStatistics do
  context 'loading email message statistics' do
    let(:client) { double('client') }
    let(:href) { '/reports/messages/email/statistics' }

    before do
      @statistics = GovDelivery::TMS::ReportsMessagesEmailStatistics.new(client, href, {})
    end

    it 'gets OK with params' do
      params = {start: Time.now.beginning_of_hour - 7.days, end: Time.now.beginning_of_hour}
      stats = {:recipients => {:new => 5, :sending => 3, :inconclusive => 2, :blacklisted => 1, :canceled => 7, :sent => 80, :failed => 2} }


      expect(@statistics.client).to receive('get').with(href, params).and_return(double('response', status: 200, body: stats))
      @statistics.get(params)
      expect(@statistics.recipients).to eq(stats[:recipients])
      expect(@statistics.recipients[:sent]).to eq(80)
    end
  end
end
