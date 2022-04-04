require 'spec_helper'

describe GovDelivery::TMS::EmailTemplate do
  context 'creating a list of email templates' do
    let(:client) do
      double('client')
    end
    before do
      @templates = GovDelivery::TMS::EmailTemplates.new(client, '/templates/email')
    end

    it 'should be able to get a list of email templates' do
      response = [
        {
          'id'                         => '1',
          'uuid'                       => 'new-template',
          'body'                       => 'Template 1',
          'subject'                    => 'This is the template 1 subject',
          'link_tracking_parameters'   => 'test=ok&hello=world',
          'macros'                     => { 'MACRO1' => '1' },
          'open_tracking_enabled'      => true,
          'click_tracking_enabled'     => true,
          'created_at'                 => 'sometime',
          '_links'                     => { 'self' => '/templates/email/new-template', 'account' => '/accounts/1', 'from_address' => '/from_addresses/1' }
        }
      ]

      expect(@templates.client).to receive('get').with('/templates/email', {}).and_return(double('response', status: 200, body: response, headers: {}))
      @templates.get
      expect(@templates.collection.length).to eq(1)
    end
  end

  context 'creating an email template' do
    let(:client) do
      double('client')
    end
    before do
      @template = GovDelivery::TMS::EmailTemplate.new(client, '/templates/email',         uuid:                       'new-template',
                                                                                          body:                       'Template 1',
                                                                                          subject:                    'This is the template 1 subject',
                                                                                          link_tracking_parameters:   'test=ok&hello=world',
                                                                                          macros:                     { 'MACRO1' => '1' },
                                                                                          open_tracking_enabled:      true,
                                                                                          click_tracking_enabled:     true)
    end

    it 'should render linkable attrs in json hash' do
      @template.links[:from_address] = '1'
      @template.links[:invalid] = '2'
      links = @template.to_json[:_links]
      expect(links[:from_address]).to eq('1')
      expect(links[:invalid]).to be_nil
    end

    it 'should clear the links property after a successful post' do
      @template.links[:from_address] = '1'
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 201, body: {}))
      @template.post
      links = @template.to_json[:_links]
      expect(links).to be_nil
    end

    it 'should not clear the links property after an invalid post' do
      @template.links[:from_address] = '1'
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 400, body: {}))
      @template.post
      links = @template.to_json[:_links]
      expect(links[:from_address]).to eq('1')
    end

    it 'should post successfully' do
      response = {
        'id'                         => '1',
        'uuid'                       => 'new-template',
        'body'                       => 'Template 1',
        'subject'                    => 'This is the template 1 subject',
        'link_tracking_parameters'   => 'test=ok&hello=world',
        'macros'                     => { 'MACRO1' => '1' },
        'open_tracking_enabled'      => true,
        'click_tracking_enabled'     => true,
        'message_type_code'          => 'salutations',
        'created_at'                 => 'sometime',
        '_links'                     => { 'self' => '/templates/email/new-template',
                                          'account' => '/accounts/1',
                                          'message_type' => '/message_types/abc',
                                          'from_address' => '/from_addresses/1' }
      }
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 201, body: response))
      @template.post
      expect(@template.id).to eq('1')
      expect(@template.uuid).to eq('new-template')
      expect(@template.body).to eq('Template 1')
      expect(@template.subject).to eq('This is the template 1 subject')
      expect(@template.link_tracking_parameters).to eq('test=ok&hello=world')
      expect(@template.macros).to eq('MACRO1' => '1')
      expect(@template.open_tracking_enabled).to eq(true)
      expect(@template.click_tracking_enabled).to eq(true)
      expect(@template.message_type_code).to eql('salutations')
      expect(@template.created_at).to eq('sometime')
      expect(@template.from_address).to be_a(GovDelivery::TMS::FromAddress)
      expect(@template.message_type).to be_a(GovDelivery::TMS::MessageType)
    end
  end

  context 'handling errors at the template level' do
    let(:client) do
      double('client')
    end
    before do
      @template = GovDelivery::TMS::EmailTemplate.new(client, '/templates/email/1')
    end

    it 'should handle errors' do
      response = { 'errors' => { body: "can't be nil" } }
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 422, body: response))
      @template.post
      expect(@template.errors).to eq(body: "can't be nil")
    end

    it 'should handle 401 errors' do
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 401))
      expect { @template.post }.to raise_error('401 Not Authorized')
    end

    it 'should handle 404 errors' do
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 404))
      expect { @template.post }.to raise_error("Can't POST to /templates/email/1")
    end
  end

  context 'handling errors at the email_templates root level' do
    let(:client) do
      double('client')
    end
    before do
      @template = GovDelivery::TMS::EmailTemplate.new(client, '/templates/email')
    end

    it 'should handle errors' do
      response = { 'errors' => { body: "can't be nil" } }
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 422, body: response))
      @template.post
      expect(@template.errors).to eq(body: "can't be nil")
    end

    it 'should handle 401 errors' do
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 401))
      expect { @template.post }.to raise_error('401 Not Authorized')
    end

    it 'should handle 404 errors' do
      expect(@template.client).to receive('post').with(@template).and_return(double('response', status: 404))
      expect { @template.post }.to raise_error("Can't POST to /templates/email")
    end
  end
end
