FactoryBot.define do
  factory :remand_reason, class: VACOLS::RemandReason do
    rmdkey "123456"
    rmdissseq "3"
    rmdval "AB"
    rmddev "R2"
    rmdmdusr "TEST1"
    rmdmdtim { VacolsHelper.local_time_with_utc_timezone }
  end
end
