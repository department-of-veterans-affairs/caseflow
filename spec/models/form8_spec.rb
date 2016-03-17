require_relative "../rails_helper"
describe Form8 do
  context "#representative" do
    let(:form8) { Form8.new }
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
    let(:appeal) { Form8.new(remarks: "Hello, World") }

    it "rolls over remarks properly" do
      expect(appeal.remarks).to eq("Hello, World")

      expect(appeal.remarks_rollover?).to be_falsey
      expect(appeal.remarks_initial).to eq("Hello, World")
      expect(appeal.remarks_continued).to be_nil

      appeal.remarks = "A" * 606 + "Hello, World!"

      expect(appeal.remarks_rollover?).to be_truthy
      expect(appeal.remarks_initial).to eq("A" * 575 + " (see continued remarks page 2)")
      expect(appeal.remarks_continued).to eq("\n \nContinued:\n" + ("A" * 31) + "Hello, World!")
    end

    it "rolls over remarks with newlines properly" do
      appeal.remarks = "\n" * 6 + "Hello, World!"

      expect(appeal.remarks_rollover?).to be_truthy
      expect(appeal.remarks_initial).to eq("\n" * 5 + " (see continued remarks page 2)")
      expect(appeal.remarks_continued).to eq("\n \nContinued:\nHello, World!")
    end

    it "rolls over wrapped text properly" do
      appeal.remarks = "On February 10, 2007, Obama announced his candidacy for President of the United States in " \
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

      expect(appeal.remarks_rollover?).to be_truthy
      expect(appeal.remarks_initial).to eq("On February 10, 2007, Obama announced his candidacy for President of the " \
                                               "United States in front of the Old State Capitol building in " \
                                               "Springfield, Illinois.[104][105] The choice of the announcement site " \
                                               "was viewed as symbolic because it was also where Abraham Lincoln " \
                                               "delivered his historic \"House Divided\" speech in 1858.[104][106] " \
                                               "Obama emphasized issues of rapidly ending the Iraq War, increasing " \
                                               "energy independence, and reforming the health care system,[107] in a " \
                                               "campaign that projected themes of hope and change.[108] Numerous " \
                                               "candidates entered the Democratic (see continued remarks page 2)")

      expect(appeal.remarks_continued).to eq("\n \nContinued:\nParty presidential primaries. The field narrowed to a " \
                                                 "duel between Obama and Senator Hillary Clinton after early " \
                                                 "contests, with the race remaining close throughout the primary " \
                                                 "process but with Obama gaining a steady lead in pledged delegates " \
                                                 "due to better long-range planning, superior fundraising, dominant " \
                                                 "organizing in caucus states, and better exploitation of delegate " \
                                                 "allocation rules.[109] On June 7, 2008, Clinton ended her campaign " \
                                                 "and endorsed Obama.[110]")
    end
  end

  context "#service_connection_for_rolled" do
    let(:appeal) { Form8.new(service_connection_for: "one\ntwo\nthree") }

    it "rolls over properly" do
      expect(appeal.service_connection_for_initial).to eq("one\ntwo (see continued remarks page 2)")
      expect(appeal.remarks_continued).to eq("\n \nService Connection For Continued:\nthree")
    end

    it "rolls over and combines with remarks rollover" do
      appeal.remarks = "one\ntwo\n\three\nfour\nfive\nsix\nseven"
      expect(appeal.service_connection_for_initial).to eq("one\ntwo (see continued remarks page 2)")
      expect(appeal.remarks_continued).to eq("\n \nContinued:\nseven" \
                                                 "\n \nService Connection For Continued:\nthree")
    end
  end

  context ".from_appeal" do
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
        appellant_first_name: "Micah",
        appellant_last_name: "Bobby",
        appellant_relationship: "Brother",
        veteran_first_name: "Shane",
        veteran_last_name: "Bobby",
        nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        form9_date: 1.day.ago,
        insurance_loan_number: "1337"
      )
    end

    it "creates new form8 with values copied over correctly" do
      form8 = Form8.from_appeal(appeal)

      expect(form8).to have_attributes(
        vacols_id: "VACOLS-ID",
        appellant_name: "Micah, Bobby",
        appellant_relationship: "Brother",
        file_number: "VBMS-ID",
        veteran_name: "Bobby, Shane",
        insurance_loan_number: "1337",
        service_connection_nod_date: 3.days.ago,
        increased_rating_nod_date: 3.days.ago,
        other_nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        certification_date: Time.zone.now
      )
    end
  end
end
