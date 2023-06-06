require 'rails_helper'

# This is the command to run rspec in the console
# bundle exec rspec spec/controllers/idt/api/v2/distributions_controller_spec.rb

# Here is where you look at code coverage
#open coverage/index.html

RSpec.describe Idt::Api::V2::DistributionsController, type: :controller do
  describe '#get_distribution' do
    let(:user) { create(:user) }
    let(:distribution_id) { 'example_distribution_id' }
    let(:distribution) { double('Distribution', code: 200) }
    let(:token) do
        key, token = Idt::Token.generate_one_time_key_and_proposed_token
        Idt::Token.activate_proposed_token(key, user.css_id)
        token
      end
    let(:params) { :distribution_id }

    before do
      allow(controller).to receive(:params).and_return({ distribution_id: distribution_id })
      allow(controller).to receive(:token).and_return(token) # Stub the token retrieval
      allow(VbmsDistribution).to receive(:exists?).with(id: distribution_id).and_return(true)
      allow(PacManService).to receive(:get_distribution_request).with(distribution_id).and_return(distribution)
    end

    context 'when distribution_id is blank or invalid' do
      let(:distribution_id) { '' }

      it 'renders an error with status 400' do
        error_message = 'Distribution Does Not Exist Or Id is blank'
        expect(controller).to receive(:render_error).with(400, error_message, distribution_id)
        controller.get_distribution
      end
    end

    context 'when PacManService fails with a 404 error' do
      let(:distribution) { double('Distribution', code: 404) }

      it 'renders an error based on the response code' do
        error_message = 'Distribution Does Not Exist At This Time'
        expect(controller).to receive(:render_error).with(404, error_message, distribution_id)
        controller.get_distribution
      end
    end

    context 'when PacManService fails with a 500 error' do
      let(:distribution) { double('Distribution', code: 500) }

      it 'renders an error with status 500' do
        error_message = 'Internal Server Error'
        expect(controller).to receive(:render_error).with(500, error_message, distribution_id)
        controller.get_distribution
      end
    end

      it 'returns the expected converted response' do
        response = HTTPI::Response.new(
        200,
        {},
        OpenStruct.new(
          "id": 1,
          "recipient": {
            "type": "recipient_type",
            "id": "recipient_id",
            "name": "recipient_name"
          },
          "description": "description",
          "communicationPackageId": "package_id",
          "destinations": [{
            "type": "destination_type",
            "id": "destination_id",
            "status": "destination_status",
            "cbcmSendAttemptDate": "send_attempt_date",
            "addressLine1": "address_line_1",
            "addressLine2": "address_line_2",
            "addressLine3": "address_line_3",
            "addressLine4": "address_line_4",
            "addressLine5": "address_line_5",
            "addressLine6": "address_line_6",
            "treatLine2AsAddressee": true,
            "treatLine3AsAddressee": false,
            "city": "city",
            "state": "state",
            "postalCode": "postal_code",
            "countryName": "country_name",
            "countryCode": "country_code"
          }],
          "status": "destination_status",
          "sentToCbcmDate": "sent_to_cbcm_date"
        )
      )

        new_table = {
            table: {
            id: 1,
            recipient: {
              type: 'recipient_type',
              id: 'recipient_id',
              name: 'recipient_name'
            },
            description: 'description',
            communication_package_id: 'package_id',
            destinations: [
              {
                type: 'destination_type',
                id: 'destination_id',
                status: 'destination_status',
                cbcm_send_attempt_date: 'send_attempt_date',
                address_line_1: 'address_line_1',
                address_line_2: 'address_line_2',
                address_line_3: 'address_line_3',
                address_line_4: 'address_line_4',
                address_line_5: 'address_line_5',
                address_line_6: 'address_line_6',
                treat_line_2_as_addressee: true,
                treat_line_3_as_addressee: false,
                city: 'city',
                state: 'state',
                postal_code: 'postal_code',
                country_name: 'country_name',
                country_code: 'country_code'
              }
            ],
            status: 'destination_status',
            sent_to_cbcm_date: 'sent_to_cbcm_date'
          }
        }

        result = subject.send(:converted_response, response)

        expect(result).to eq(new_table)
      end
    end

    describe '#render_error' do
    let(:status) { 400 }
    let(:message) { 'Participant With UUID Not Valid' }
    let(:distribution_id) { '123456' }
    let(:error_uuid) { SecureRandom.uuid }

    it 'renders the error response with correct status, message, and distribution ID' do
      allow(SecureRandom).to receive(:uuid).and_return(error_uuid)
      error_message = "[IDT] Http Status Code: #{status}, #{message}, (Distribution ID: #{distribution_id})"

      expect(Rails.logger).to receive(:error).with("#{error_message}Error ID: #{error_uuid}")
      expect(Raven).to receive(:capture_exception).with(error_message, extra: { error_uuid: error_uuid })

      expect(controller).to receive(:render).with(
        json: {
          "Errors": [
            {
              "Message": error_message
            }
          ],
          "Error UUID": error_uuid
        }
      )

      controller.send(:render_error, status, message, distribution_id)
    end
  end
end


