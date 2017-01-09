class Fakes::BGSService
  def get_eps(veteran_id)
    [{
      claim_receive_date: Date.today - 20.days,
      claim_type_code: '172GRANT',
      status_type_code: 'PEND'
    },
    {
      claim_receive_date: Date.today + 10.days,
      claim_type_code: '170RMD',
      status_type_code: 'CLR'
    },
    {
      claim_receive_date: Date.today,
      claim_type_code: '172BVAG',
      status_type_code: 'CAN'
    },
    {
      claim_receive_date: Date.today - 200.days,
      claim_type_code: '172BVAG',
      status_type_code: 'CLR'
    }]
  end
end
