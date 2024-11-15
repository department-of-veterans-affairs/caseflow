# frozen_string_literal: true

describe Events::PersonUpdated do
  let(:attributes) do
    Events::PersonUpdated::Attributes.new(
      {
        first_name: "John",
        middle_name: "",
        last_name: "Smith",
        name_suffix: "Sr.",
        ssn: "444556666",
        date_of_birth: Date.new(1950, 1, 1),
        email_address: "john@thesmiths.org",
        date_of_death: Date.new(2000, 1, 1),
        file_number: "444556666"
      }
    )
  end

  let(:participant_id) { 54_321 }
  let(:is_veteran) { true }
  let(:person) do
    FactoryBot.create(
      :person,
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      middle_name: Faker::Name.first_name,
      name_suffix: Faker::Name.suffix,
      email_address: Faker::Internet.email,
      ssn: "777889999",
      participant_id: participant_id
    )
  end
  let(:veteran) { FactoryBot.create(:veteran, participant_id: participant_id) }
  let(:consumer_event_id) { SecureRandom.uuid }

  let(:redis) { Redis.new(url: Rails.application.secrets.redis_url_cache) }
  let(:lock_key) { "RedisMutex:PersonUpdated:#{consumer_event_id}" }

  subject { described_class.new(consumer_event_id, participant_id, is_veteran, attributes) }

  it "throws a Redis lock error when lock fails" do
    redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)

    expect { subject.call }.to raise_error(
      Caseflow::Error::RedisLockFailed
    )

    redis.del(lock_key)
  end

  let!(:event_person_info) do
    {
      "before_data" => {
        "id" => person.id,
        "updated_at" => kind_of(String),
        "created_at" => kind_of(String),
        "participant_id" => participant_id.to_s,
        "date_of_birth" => person.date_of_birth.to_s,
        "first_name" => person.first_name,
        "last_name" => person.last_name,
        "middle_name" => person.middle_name,
        "name_suffix" => person.name_suffix,
        "email_address" => person.email_address,
        "ssn" => person.ssn
      },
      "record_data" => {
        "id" => person.id,
        "updated_at" => kind_of(String),
        "created_at" => kind_of(String),
        "participant_id" => participant_id.to_s,
        "date_of_birth" => attributes.date_of_birth.to_s,
        "first_name" => attributes.first_name,
        "last_name" => attributes.last_name,
        "middle_name" => attributes.middle_name,
        "name_suffix" => attributes.name_suffix,
        "email_address" => attributes.email_address,
        "ssn" => attributes.ssn,
        "update_type" => "U"
      }
    }
  end

  let!(:event_veteran_info) do
    {
      "before_data" => {
        "id" => veteran.id,
        "updated_at" => kind_of(String),
        "created_at" => kind_of(String),
        "participant_id" => participant_id.to_s,
        "date_of_birth" => Veteran.first.date_of_birth.to_s,
        "first_name" => veteran.first_name,
        "last_name" => veteran.last_name,
        "middle_name" => veteran.middle_name,
        "name_suffix" => veteran.name_suffix,
        "email_address" => veteran.email_address,
        "ssn" => veteran.ssn
      },
      "record_data" => {
        "id" => veteran.id,
        "updated_at" => kind_of(String),
        "created_at" => kind_of(String),
        "participant_id" => participant_id.to_s,
        "date_of_birth" => attributes.date_of_birth.to_s,
        "first_name" => attributes.first_name,
        "last_name" => attributes.last_name,
        "middle_name" => attributes.middle_name,
        "name_suffix" => attributes.name_suffix,
        "email_address" => veteran.email_address,
        "ssn" => attributes.ssn,
        "update_type" => "U"
      }
    }
  end

  it "updates matching veteran and person records" do
    # rubocop:disable Style/BlockDelimiters
    # rubocop:disable Layout/MultilineMethodCallIndentation
    expect {
      subject.call
    }.to change { person.reload.first_name }.to(attributes.first_name)
    .and change { veteran.reload.first_name }.to(attributes.first_name)
    .and change { person.reload.last_name }.to(attributes.last_name)
    .and change { veteran.reload.last_name }.to(attributes.last_name)
    .and change { person.reload.middle_name }.to(attributes.middle_name)
    .and change { veteran.reload.middle_name }.to(attributes.middle_name)
    .and change { person.reload.name_suffix }.to(attributes.name_suffix)
    .and change { veteran.reload.name_suffix }.to(attributes.name_suffix)
    .and change { person.reload.ssn }.to(attributes.ssn)
    .and change { veteran.reload.ssn }.to(attributes.ssn)
    .and change { person.reload.date_of_birth }.to(attributes.date_of_birth)
    .and change { person.reload.email_address }.to(attributes.email_address)
    .and change { veteran.reload.date_of_death }.to(attributes.date_of_death)
    .and change { veteran.reload.file_number }.to(attributes.file_number)
    # rubocop:enable Style/BlockDelimiters
    # rubocop:enable Layout/MultilineMethodCallIndentation

    event = Event.find_by(reference_id: consumer_event_id)
    expect(event).to be_kind_of(PersonUpdatedEvent)

    person_event, veteran_event = event.event_records

    expect(person_event.event_id).to eq(event.id)
    expect(person_event.evented_record_type).to eq("Person")
    expect(person_event.evented_record_id).to eq(person.id)
    expect(person_event.info["before_data"]).to match(event_person_info["before_data"])
    expect(person_event.info["record_data"]).to match(event_person_info["record_data"])

    expect(veteran_event.event_id).to eq(event.id)
    expect(veteran_event.evented_record_type).to eq("Veteran")
    expect(veteran_event.evented_record_id).to eq(veteran.id)
    expect(veteran_event.info["before_data"]).to match(event_veteran_info["before_data"])
    expect(veteran_event.info["record_data"]).to match(event_veteran_info["record_data"])
  end
end
