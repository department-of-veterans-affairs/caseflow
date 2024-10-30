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
  let(:person) { FactoryBot.create(:person, participant_id: participant_id) }
  let(:veteran) { FactoryBot.create(:veteran, participant_id: participant_id) }
  let(:event_id) { SecureRandom.uuid }

  let(:redis) { Redis.new(url: Rails.application.secrets.redis_url_cache) }
  let(:lock_key) { "RedisMutex:PersonUpdated:#{event_id}" }

  subject { described_class.new(event_id, participant_id, is_veteran, attributes) }

  it "throws a Redis lock error when lock fails" do
    redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)

    expect { subject.call }.to raise_error(
      Caseflow::Error::RedisLockFailed
    )

    redis.del(lock_key)
  end

  it "updates matching veteran and person records" do
    expect { subject.call }.to(
      change do
        [
          [person.reload.first_name, veteran.reload.first_name],
          [person.reload.last_name, veteran.reload.last_name],
          [person.reload.middle_name, veteran.reload.middle_name],
          [person.reload.name_suffix, veteran.reload.name_suffix],
          [person.reload.ssn, veteran.reload.ssn],
          [person.reload.date_of_birth, nil],
          [person.reload.email_address, nil],
          [nil, veteran.reload.date_of_death],
          [nil, veteran.reload.file_number]
        ]
      end.to(
        [
          [attributes.first_name] * 2,
          [attributes.last_name] * 2,
          [attributes.middle_name] * 2,
          [attributes.name_suffix] * 2,
          [attributes.ssn] * 2,
          [attributes.date_of_birth, nil],
          [attributes.email_address, nil],
          [nil, attributes.date_of_death],
          [nil, attributes.file_number]
        ]
      )
    )
  end
end
