# frozen_string_literal: true

describe Form8, :all_dbs do
  initial_fields = [:_initial_appellant_name,
                    :_initial_appellant_relationship,
                    :_initial_veteran_name,
                    :_initial_insurance_loan_number,
                    :_initial_service_connection_notification_date,
                    :_initial_increased_rating_notification_date,
                    :_initial_other_notification_date,
                    :_initial_representative_name,
                    :_initial_representative_type,
                    :_initial_hearing_requested,
                    :_initial_ssoc_required]

  let(:form8) do
    create(:default_form8)
  end

  let(:appeal) do
    create(:legacy_appeal, vacols_case: vacols_case)
  end

  let(:vacols_case) do
    create(:case_with_ssoc)
  end

  context "#attributes" do
    let(:form8) do
      create(:default_form8, file_number: "1234QWERTY")
    end
    subject { form8 }

    it do
      is_expected.to have_attributes(appellant_name: "Brad Pitt",
                                     appellant_relationship: "Fancy man",
                                     file_number: "1234QWERTY",
                                     veteran_name: "Joe Patriot")
    end
  end

  context "#update_from_appeal" do
    it "populates _initial_ fields with the same values as their counterparts" do
      form8.assign_attributes_from_appeal(appeal)

      initial_fields.each do |initial_field|
        f = initial_field.to_s.sub "_initial_", ""
        field = f.to_sym
        expect(form8[field]).to eq(form8[initial_field])
      end
    end
  end

  context "#attributes" do
    it "does not return initial attributes" do
      form8.assign_attributes_from_appeal(appeal)
      attributes = form8.attributes

      initial_fields.each do |initial_field|
        expect(attributes[initial_field]).to eq(nil)
      end
    end
  end

  context "#update_from_string_params" do
    it "takes string dates passed by the client and turns them into Date objects for persistence" do
      date_fields = [
        :certification_date,
        :service_connection_notification_date,
        :increased_rating_notification_date,
        :other_notification_date,
        :soc_date
      ]

      params = {}
      date_fields.each do |date_field|
        params[date_field] = "02/31/2005"
      end

      form8.update_from_string_params(params)

      date_fields.each do |date_field|
        expect(form8[date_field]).to eq Date.strptime("02/31/2005", "%m/%d/%Y")
      end
    end
  end

  context "#hearing_on_file" do
    subject { form8.hearing_on_file }
    before { form8.hearing_transcript_on_file = "Yes" }

    context "when hearing_held is set to Yes" do
      before { form8.hearing_held = "Yes" }
      it { is_expected.to eq("Yes") }
    end

    context "when hearing_held is set to No" do
      before { form8.hearing_held = "No" }
      it { is_expected.to be_falsey }
    end
  end

  context "#representative" do
    subject { form8.representative }
    before { form8.representative_name = "Joe" }

    context "when representative_type isn't other" do
      before { form8.representative_type = "Appeal" }
      it { is_expected.to eq "Joe - Appeal" }
    end

    context "when representative_type is other" do
      before do
        form8.representative_type = "Other"
        form8.representative_type_specify_other = "Bossman"
      end
      it { is_expected.to eq "Joe - Bossman" }
    end
  end

  context "#remarks_rolled" do
    let(:form8) do
      create(:default_form8, remarks: "Hello, World")
    end

    it "rolls over remarks properly" do
      expect(form8.remarks).to eq("Hello, World")

      expect(form8.remarks_rollover?).to be_falsey
      expect(form8.remarks_initial).to eq("Hello, World")
      expect(form8.remarks_continued).to be_nil

      form8.remarks = "A" * 606 + "Hello, World!"

      expect(form8.remarks_rollover?).to be_truthy
      expect(form8.remarks_initial).to eq("A" * 575 + " (see continued remarks page 2)")
      expect(form8.remarks_continued).to eq("\n \nContinued:\n" + ("A" * 31) + "Hello, World!")
    end

    it "rolls over remarks with newlines properly" do
      form8.remarks = "\n" * 6 + "Hello, World!"

      expect(form8.remarks_rollover?).to be_truthy
      expect(form8.remarks_initial).to eq("\n" * 5 + " (see continued remarks page 2)")
      expect(form8.remarks_continued).to eq("\n \nContinued:\nHello, World!")
    end

    it "rolls over wrapped text properly" do
      form8.remarks = "On February 10, 2007, Obama announced his candidacy for President of the United States in " \
      "front of the Old State Capitol building in Springfield, Illinois.[104][105] The choice of the announcement " \
      "site was viewed as symbolic because it was also where Abraham Lincoln delivered his historic \"House " \
      "Divided\" speech in 1858.[104][106] Obama emphasized issues of rapidly ending the Iraq War, increasing " \
      "energy independence, and reforming the health care system,[107] in a campaign that projected themes of " \
      "hope and change.[108] Numerous candidates entered the Democratic Party presidential primaries. The field " \
      "narrowed to a duel between Obama and Senator Hillary Clinton after early contests, with the race remaining " \
      "close throughout the primary process but with Obama gaining a steady lead in pledged delegates due to " \
      "better long-range planning, superior fundraising, dominant organizing in caucus states, and better " \
      "exploitation of delegate allocation rules.[109] On June 7, 2008, Clinton ended her campaign and endorsed " \
      "Obama.[110]"

      expect(form8.remarks_rollover?).to be_truthy
      expect(form8.remarks_initial).to eq("On February 10, 2007, Obama announced his candidacy for President of the " \
                                               "United States in front of the Old State Capitol building in " \
                                               "Springfield, Illinois.[104][105] The choice of the announcement site " \
                                               "was viewed as symbolic because it was also where Abraham Lincoln " \
                                               "delivered his historic \"House Divided\" speech in 1858.[104][106] " \
                                               "Obama emphasized issues of rapidly ending the Iraq War, increasing " \
                                               "energy independence, and reforming the health care system,[107] in a " \
                                               "campaign that projected themes of hope and change.[108] Numerous " \
                                               "candidates entered the Democratic (see continued remarks page 2)")

      expect(form8.remarks_continued).to eq("\n \nContinued:\nParty presidential primaries. The field narrowed to a " \
                                                 "duel between Obama and Senator Hillary Clinton after early " \
                                                 "contests, with the race remaining close throughout the primary " \
                                                 "process but with Obama gaining a steady lead in pledged delegates " \
                                                 "due to better long-range planning, superior fundraising, dominant " \
                                                 "organizing in caucus states, and better exploitation of delegate " \
                                                 "allocation rules.[109] On June 7, 2008, Clinton ended her campaign " \
                                                 "and endorsed Obama.[110]")
    end
  end

  context "#remarks_continued" do
    subject { form8.remarks_continued }
    let(:line) { "Words\n" }
    let(:form8) do
      create(:default_form8,
             remarks: remarks,
             service_connection_for: service_connection_for,
             increased_rating_for: increased_rating_for,
             other_for: other_for)
    end

    context "when no fields roll over" do
      let(:service_connection_for) { "" }
      let(:increased_rating_for) { "" }
      let(:other_for) { "" }
      let(:remarks) { "" }

      it { is_expected.to be_nil }
    end

    context "when all fields roll over" do
      let(:service_connection_for) { "#{line * 2}SERVICE CONNECTION YES" }
      let(:increased_rating_for) { "#{line * 2}INCREASED RATING YEAH" }
      let(:other_for) { "#{line * 2}OTHER THINGS" }
      let(:remarks) { "#{line * 6}REMARKS WOO" }

      it do
        is_expected.to eq("\n \nContinued:\nREMARKS WOO" \
                             "\n \nService Connection For Continued:\nSERVICE CONNECTION YES" \
                             "\n \nIncreased Rating For Continued:\nINCREASED RATING YEAH" \
                             "\n \nOther Continued:\nOTHER THINGS")
      end
    end
  end

  context "#service_connection_for_rolled" do
    let(:form8) do
      create(:default_form8, service_connection_for: "one\ntwo\nthree")
    end

    it "rolls over properly" do
      expect(form8.service_connection_for_initial).to eq("one\ntwo (see continued remarks page 2)")
      expect(form8.remarks_continued).to eq("\n \nService Connection For Continued:\nthree")
    end

    it "rolls over and combines with remarks rollover" do
      form8.remarks = "one\ntwo\n\three\nfour\nfive\nsix\nseven"
      expect(form8.service_connection_for_initial).to eq("one\ntwo (see continued remarks page 2)")
      expect(form8.remarks_continued).to eq("\n \nContinued:\nseven" \
                                                 "\n \nService Connection For Continued:\nthree")
    end
  end

  context "#pdf_location" do
    let(:path) { form8.pdf_location }

    before do
      Form8PdfService.save_pdf_for!(form8)
    end

    it "should fetch the PDF from s3 and save it locally if the PDF does not exists locally" do
      File.delete(path)
      expect(File.exist?(path)).to eq false
      form8.pdf_location
      expect(File.exist?(path)).to eq true
    end
  end

  context "#document_type_id" do
    subject { Form8.new.document_type_id }
    it { is_expected.to eq("178") }
  end

  context ".from_appeal" do
    before do
      Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    end

    after do
      Timecop.return
    end

    let(:form8) do
      create(:default_form8, file_number: "VBMS-ID")
    end

    let(:appeal) do
      create(:legacy_appeal,
             vacols_case: vacols_case,
             vbms_id: "VBMS-ID",
             regional_office_key: "RO37")
    end

    let(:vacols_case) do
      create(:case_with_ssoc,
             bfkey: "VACOLS-ID",
             bfcorlid: "VBMS-ID",
             bfdrodec: (Time.zone.now - 4.days).to_date,
             bfdsoc: (Time.zone.now - 4.days).to_date,
             bfd19: (Time.zone.now - 4.days).to_date,
             bfpdnum: "1337",
             correspondent: correspondent)
    end

    let(:correspondent) do
      create(:correspondent,
             appellant_first_name: "Bobby",
             appellant_middle_initial: "A",
             appellant_last_name: "Micah",
             appellant_relationship: "Brother",
             snamef: "Shane",
             snamemi: "A",
             snamel: "Bobby")
    end

    it "creates new form8 with values copied over correctly" do
      form8.assign_attributes_from_appeal(appeal)

      expect(form8).to have_attributes(
        vacols_id: "VACOLS-ID",
        appellant_name: "Bobby A Micah",
        appellant_relationship: "Brother",
        file_number: "VBMS-ID",
        veteran_name: "Bobby, Shane, A",
        insurance_loan_number: "1337",
        service_connection_notification_date: (Time.zone.now - 4.days).to_date,
        increased_rating_notification_date: (Time.zone.now - 4.days).to_date,
        other_notification_date: (Time.zone.now - 4.days).to_date,
        soc_date: (Time.zone.now - 4.days).to_date,
        certification_date: Time.zone.now.to_date
      )
    end
  end
end
