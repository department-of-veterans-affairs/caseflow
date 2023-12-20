# frozen_string_literal: true

describe RemandReasonMapper do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  context ".convert_to_vacols_format" do
    let(:remand_reasons) do
      [{
        code: "AB",
        post_aoj: true
      },
       {
         code: "ED",
         post_aoj: false
       }]
    end

    let(:expected_response) do
      [{
        rmdval: "AB",
        rmddev: "R2",
        rmdmdusr: "TEST1",
        rmdmdtim: VacolsHelper.local_time_with_utc_timezone

      },
       {
         rmdval: "ED",
         rmddev: "R1",
         rmdmdusr: "TEST1",
         rmdmdtim: VacolsHelper.local_time_with_utc_timezone
       }]
    end

    subject { RemandReasonMapper.convert_to_vacols_format("TEST1", remand_reasons) }

    it { is_expected.to eq expected_response }
  end
end
