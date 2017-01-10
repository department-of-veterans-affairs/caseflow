class Fakes::BGSService
  cattr_accessor :ep_data

  def get_eps(veteran_id)
    ep_data || [{
        benefit_claim_id: '1',
        claim_receive_date: Date.today - 20.days,
        claim_type_code: '172GRANT',
        status_type_code: 'PEND'
      },
      {
        benefit_claim_id: '2',
        claim_receive_date: Date.today + 10.days,
        claim_type_code: '170RMD',
        status_type_code: 'CLR'
      },
      {
        benefit_claim_id: '3',
        claim_receive_date: Date.today,
        claim_type_code: '172BVAG',
        status_type_code: 'CAN'
      },
      {
        benefit_claim_id: '4',
        claim_receive_date: Date.today - 200.days,
        claim_type_code: '172BVAG',
        status_type_code: 'CLR'
      }]
  end
end
