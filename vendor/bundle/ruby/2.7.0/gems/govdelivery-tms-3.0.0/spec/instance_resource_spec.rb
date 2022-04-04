require 'spec_helper'
class Foo
  include GovDelivery::TMS::InstanceResource
  writeable_attributes :bar
  collection_attribute :blah, 'EmailMessage'
  readonly_collection_attribute :shah, 'EmailMessage'
end

describe GovDelivery::TMS::InstanceResource do
  context 'creating a new inbound messages list' do
    let(:happy_response) do
      double(status: 201,  body: {})
    end

    let(:client) do
      double('client', post: happy_response, get: happy_response)
    end

    before do
      @instance_resource = Foo.new(client)
    end

    it 'should POST' do
      @instance_resource.bar = 'OMG'
      expect(@instance_resource.post).to be_truthy
    end

    it 'should correctly reflect on collection resources' do
      expect(@instance_resource.blah.class).to eq(GovDelivery::TMS::EmailMessage)
      expect(@instance_resource.shah.class).to eq(GovDelivery::TMS::EmailMessage)
    end

    it 'should ignore nils in to_json' do
      @instance_resource.bar = nil
      expect(@instance_resource.to_json).to eq({blah: {recipients: [], opened: [], clicked: [], sent: [], failed: []}})
    end

    it 'should ignore nils in to_json unless an attribute in nullable_attributes' do
      @instance_resource.class.nullable_attributes :bar
      @instance_resource.bar = nil
      expect(@instance_resource.to_json).to eq({blah: {recipients: [], opened: [], clicked: [], sent: [], failed: []},
                                                bar: nil})
      @instance_resource.class.instance_variable_set :@nullable_attributes, []
    end

    it 'should not GET on initialization' do
      expect(client).not_to receive(:get)
      Foo.new(client, 'https://example.com/foos/1')
    end

    it 'should return self on successful get' do
      expect(client).to receive(:get)
      foo = Foo.new(client, 'https://example.com/foos/1')
      expect(foo).not_to be_new_record
      expect(foo.get).to eq(foo)
    end

    %w(get post put delete).each do |verb|
      it "should blow up on invalid #{verb}!" do
        expect(client).to(receive(verb)).and_return(double('response', status: 404, body: '{}'))
        foo = Foo.new(client, 'https://example.com/foos/1')
        expect do
          foo.send("#{verb}!")
        end.to raise_error("GovDelivery::TMS::Errors::Invalid#{verb.capitalize}".constantize)
      end
    end

    it 'it exposes its attributes hash' do
      expect(@instance_resource.attributes).to eq({})
    end
  end
end
