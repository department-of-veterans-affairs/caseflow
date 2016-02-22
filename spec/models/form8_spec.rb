describe Form8 do
  context ".new_from_appeal" do
    before do
      Timecop.freeze
    end

    after do
      Timecop.return
    end

    let(:appeal) do
      Appeal.new(
        vacols_id: "VACOLS-ID",
        vbms_id: "VBMS-ID",
        appellant_name: "Micah Bobby",
        appellant_relationship: "Brother",
        veteran_name: "Shane Bobby",
        nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        form9_date: 1.day.ago,
        insurance_loan_number: "1337"
      )
    end

    it "creates new form8 with values copied over correctly" do
      form8 = Form8.new_from_appeal(appeal)

      expect(form8).to have_attributes(
        vacols_id: "VACOLS-ID",
        appellant_name: "Micah Bobby",
        appellant_relationship: "Brother",
        file_number: "VBMS-ID",
        veteran_name: "Shane Bobby",
        insurance_loan_number: "1337",
        service_connection_nod_date: 3.days.ago,
        increased_rating_nod_date: 3.days.ago,
        other_nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        certification_date: Time.now
      )
    end
  end
end
