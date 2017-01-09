describe Form8PdfService do
  # TODO(alex): this file is undertested. Add more tests
  # as we make modifications to it.
  let(:form8) do
    Form8.new(
      # regular string field
      appellant_name: "Brad Pitt",
      appellant_relationship: "Fancy man",
      file_number: "1234QWERTY",
      veteran_name: "Joe Patriot",

      # hash/selection fields
      power_of_attorney: "POA",
      hearing_requested: "Yes",
      ssoc_required: "Not required",

      # date field
      soc_date: "2001-11-23T04:05:06+00:00",

      # remarks and rollover fields

      remarks: "On February 10, 2007, Obama announced his candidacy for President of the " \
               "United States in front of the Old State Capitol building in " \
               "Springfield, Illinois.[104][105] The choice of the announcement site " \
               "was viewed as symbolic because it was also where Abraham Lincoln " \
               "delivered his historic \"House Divided\" speech in 1858.[104][106] " \
               "Obama emphasized issues of rapidly ending the Iraq War, increasing " \
               "energy independence, and reforming the health care system,[107] in a " \
               "campaign that projected themes of hope and change.[108] Numerous " \
               "candidates entered the Democratic (see continued remarks page 2)" \
               "\n \nContinued:\nParty presidential primaries. The field narrowed to a " \
               "duel between Obama and Senator Hillary Clinton after early " \
               "contests, with the race remaining close throughout the primary " \
               "process but with Obama gaining a steady lead in pledged delegates " \
               "due to better long-range planning, superior fundraising, dominant " \
               "organizing in caucus states, and better exploitation of delegate " \
               "allocation rules.[109] On June 7, 2008, Clinton ended her campaign " \
               "and endorsed Obama.[110]",


      # conditional other field
      certifying_official_title: "Attorney",
      certifying_official_title_specify_other: "Mugatu"
    )
  end

  context ".pdf_values_for" do

    let(:pdf_form8_values) do
      Form8PdfService.pdf_values_for(form8)
    end

    it "goes through the fields" do
    end

    # there's no reason to test all the possible fields as we would be recreating the logic from the class itself
    it "populates string fields correctly" do
      expect(pdf_form8_values ).to include(
                                     "form1[0].#subform[0].#area[0].TextField1[0]"  => "Brad Pitt",
                                     "form1[0].#subform[0].#area[0].TextField1[1]" => "Fancy man",
                                     "form1[0].#subform[0].#area[0].TextField1[2]" => "1234QWERTY",
                                     "form1[0].#subform[0].#area[0].TextField1[3]" => "Joe Patriot"
                                   )
    end

    it "populates check box fields correctly" do
      expect(pdf_form8_values ).to include(
                                     "form1[0].#subform[0].#area[0].CheckBox21[0]"  => "1",
                                     "form1[0].#subform[0].#area[0].CheckBox23[4]"  => "1",
                                     "form1[0].#subform[0].#area[0].CheckBox23[13]"  => "1"
                                   )
    end

    it "populates a date field correctly" do
      expect(pdf_form8_values ).to include(
                                     "form1[0].#subform[0].#area[0].TextField1[15]"  => "11/23/2001"
                                   )
    end

    it "populates 2nd page when remarks roll over" do
      expect(pdf_form8_values).to include(
                                    "form1[0].#subform[1].TextField1[26]"  => "\n \nContinued:\n(see continued remarks page 2)\n"\
                                                                              " \nContinued:\nParty presidential primaries. The"\
                                                                              " field narrowed to a duel between Obama and Senator"\
                                                                              " Hillary Clinton after early contests, with the race"\
                                                                              " remaining close throughout the primary process but with"\
                                                                              " Obama gaining a steady lead in pledged delegates due to"\
                                                                              " better long-range planning, superior fundraising, dominant"\
                                                                              " organizing in caucus states, and better exploitation of"\
                                                                              " delegate allocation rules.[109] On June 7, 2008, Clinton"\
                                                                              " ended her campaign and endorsed Obama.[110]"
                                  )
    end

    it "uses the other specified title if official title is 'Other'" do
      form8[:certifying_official_title] = "Other"

      expect(
        pdf_form8_values["form1[0].#subform[0].#area[0].TextField1[21]"]
      ).to eq("Mugatu")
    end

    it "does not populate empty fields" do
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[19]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[25]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[15]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[20]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[16]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[17]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[22]"] ).to be_nil
      expect( pdf_form8_values["form1[0].#subform[0].#area[0].CheckBox23[26]"] ).to be_nil
    end

  end

  context ".save_pdf_for!" do
    let(:final_location) { Form8PdfService.output_location_for(form8) }

    before do
      Form8PdfService.save_pdf_for!(form8)
    end

    it "should create a file at output location" do
      expect(File.exists?(File.join(Rails.root, "tmp", "pdfs", "form8-#{form8.vacols_id}.pdf"))).to be_truthy
    end

    it "should delete temporary file" do
      expect(File.exists?(File.join(Rails.root, "tmp", "pdfs", "form8-#{form8.vacols_id}.tmp"))).to be_falsy
    end
  end

end
