Appeal.repository = Fakes::AppealRepository

puts "HELLO!"
Fakes::AppealRepository.records = {
  "123" => Fakes::AppealRepository.appeal_ready_to_certify,
  "456" => Fakes::AppealRepository.appeal_not_ready
}
