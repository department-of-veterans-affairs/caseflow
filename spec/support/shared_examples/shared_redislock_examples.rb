# frozen_string_literal: true

RSpec.shared_examples "when lock key is already in the Redis Cache" do |claim_id|
  it "throws a RedisLockFailed error" do
    redis = Redis.new(url: Rails.application.secrets.redis_url_cache)
    lock_key = "RedisMutex:EndProductEstablishment:#{claim_id}"
    redis.set(lock_key, "lock is set", nx: true, ex: 5.seconds)

    expect { subject }.to raise_error(Caseflow::Error::RedisLockFailed)

  ensure
    redis.del(lock_key)
  end
end

RSpec.shared_examples "when lock acquisition fails" do |claim_id|
  before do
    allow(RedisMutex).to receive(:with_lock).and_raise(RedisMutex::LockError)
  end

  it "logs the error message" do
    expect(Rails.logger).to receive(:error)
      .with("Failed to acquire lock for Claim ID: #{claim_id}! This Event is being"\
            " processed. Please try again later.")
    expect { subject }.to raise_error(RedisMutex::LockError)
  end
end
