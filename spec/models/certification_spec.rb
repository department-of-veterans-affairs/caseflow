# frozen_string_literal: true

describe Certification, :all_dbs do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:vacols_case) do
    create(:case_with_ssoc, :representative_american_legion)
  end

  let(:certification) do
    create(:certification, :default_representative, vacols_case: vacols_case)
  end

  let(:user) { User.find_or_create_by(station_id: 456, css_id: 124) }

  context "#async_start!" do
    subject { certification.async_start! }

    context "when appeal has already been certified" do
      let(:certification) do
        create(:certification, vacols_case: vacols_case_certified)
      end

      let(:vacols_case_certified) do
        create(:case_with_ssoc, :certified)
      end

      it "returns already_certified and sets the flag" do
        subject
        expect(certification.certification_status).to eq(:already_certified)
        expect(certification.reload.already_certified).to be_truthy
        expect(certification.form8_started_at).to be_nil
      end

      it "does not update certification fields" do
        certification.update(already_certified: true, certification_date: 2.days.ago)
        date = certification.certification_date
        subject
        expect(certification.reload.certification_date).to eq date
      end
    end

    context "when appeal is missing certification data" do
      let(:certification) do
        create(:certification, vacols_case: vacols_case_missing_data)
      end

      let(:vacols_case_missing_data) do
        create(:case_with_nod)
      end

      it "returns data_missing and sets the flag" do
        subject
        expect(certification.certification_status).to eq(:data_missing)
        expect(certification.reload.vacols_data_missing).to be_truthy
        expect(certification.form8_started_at).to be_nil
      end
    end

    context "when a document is mismatched" do
      let(:certification) do
        create(:certification, vacols_case: vacols_case_mismatch)
      end

      let(:vacols_case_mismatch) do
        create(:case_with_soc, bfd19: 3.months.ago)
      end

      it "returns mismatched_documents and sets the flag" do
        subject
        expect(certification.certification_status).to eq(:mismatched_documents)

        expect(certification.reload.nod_matching_at).to eq(Time.zone.now)
        expect(certification.soc_matching_at).to eq(Time.zone.now)
        expect(certification.form9_matching_at).to be_nil
        expect(certification.ssocs_required).to be_falsey
        expect(certification.ssocs_matching_at).to be_nil
        expect(certification.form8_started_at).to be_nil
      end

      it "is included in the relevant certification_stats" do
        subject

        expect(Certification.was_missing_doc.count).to eq(1)
        expect(Certification.was_missing_nod.count).to eq(0)
        expect(Certification.was_missing_soc.count).to eq(0)
        expect(Certification.was_missing_ssoc.count).to eq(0)
        expect(Certification.was_missing_form9.count).to eq(1)
      end
    end

    context "when ssocs are mismatched" do
      let(:certification) do
        create(:certification, vacols_case: vacols_case_ssoc_mismatch)
      end

      let(:vacols_case_ssoc_mismatch) do
        create(:case_with_ssoc, bfssoc1: 1.month.ago)
      end

      it "is included in the relevant certification_stats" do
        subject

        expect(Certification.was_missing_doc.count).to eq(1)
        expect(Certification.was_missing_nod.count).to eq(0)
        expect(Certification.was_missing_soc.count).to eq(0)
        expect(Certification.was_missing_ssoc.count).to eq(1)
        expect(Certification.was_missing_form9.count).to eq(0)
      end
    end

    context "when multiple docs are mismatched" do
      let(:certification) do
        create(:certification, vacols_case: vacols_case_multiple_mismatch)
      end

      let(:vacols_case_multiple_mismatch) do
        create(:case, bfdnod: 1.month.ago, bfdsoc: 1.month.ago, bfd19: 3.months.ago, bfssoc1: 1.month.ago)
      end

      it "is included in the relevant certification_stats" do
        subject

        expect(Certification.was_missing_doc.count).to eq(1)
        expect(Certification.was_missing_nod.count).to eq(1)
        expect(Certification.was_missing_soc.count).to eq(1)
        expect(Certification.was_missing_ssoc.count).to eq(1)
        expect(Certification.was_missing_form9.count).to eq(1)
      end
    end

    context "when appeal is ready to start" do
      let(:certification) do
        create(:certification, vacols_case: vacols_case_no_ssocs)
      end

      let(:vacols_case_no_ssocs) do
        create(:case_with_form_9)
      end

      it "returns success and sets timestamps" do
        subject
        expect(certification.certification_status).to eq(:started)

        expect(certification.reload.nod_matching_at).to eq(Time.zone.now)
        expect(certification.soc_matching_at).to eq(Time.zone.now)
        expect(certification.form9_matching_at).to eq(Time.zone.now)
        expect(certification.ssocs_required).to be_falsey
        expect(certification.ssocs_matching_at).to be_nil
        expect(certification.form8_started_at).to eq(Time.zone.now)
      end

      it "no ssoc does not trip missing ssoc stat" do
        subject
        expect(Certification.was_missing_ssoc.count).to eq(0)
      end

      context "when appeal has ssoc" do
        let(:certification) do
          create(:certification, vacols_case: vacols_case)
        end

        it "returns success and sets ssoc_required" do
          subject
          expect(certification.certification_status).to eq(:started)
          expect(certification.ssocs_required).to be_truthy
          expect(certification.ssocs_matching_at).to eq(Time.zone.now)
        end
      end

      context "when matching form8 exists" do
        context "when matching form8 is recent" do
          let!(:form8) { Form8.create(certification_id: certification.id) }
          let(:new_date) { Time.utc(2016, 7, 7, 12, 0, 0) }

          it "updates the form8's certification date" do
            Timecop.freeze(new_date)
            subject
            expect(form8.reload.certification_date).to eq(new_date.to_date)
          end
        end

        context "when matching form8 is stale (> 48 hrs old)" do
          let!(:form8) do
            Form8.create(certification_id: certification.id, updated_at: 3.days.ago)
          end
          let(:appeal) do
            certification.appeal
          end

          it "updates the form8's values from appeal" do
            subject
            expect(form8.reload.file_number).to eq(appeal.vbms_id)
          end
        end
      end

      context "when matching form8 doesn't exist" do
        # Save the certification so it has an id
        before { certification.save! }

        it "creates a new form8" do
          subject

          expect(Form8.find_by(certification_id: certification.id)).to have_attributes(
            vacols_id: certification.vacols_id,
            certification_date: Time.zone.now.to_date
          )
        end
      end
    end
  end

  context "#form8" do
    subject { certification.form8 }

    context "when a form8 exists in the db for that certification" do
      before { certification.save! }
      let!(:existing_form8) { Form8.create(certification_id: certification.id) }
      it { is_expected.to eq(existing_form8) }
    end

    context "when no saved form8 exists" do
      it { is_expected.to be_nil }
    end
  end

  context "#appeal" do
    let(:appeal) do
      create(:legacy_appeal, vacols_case: vacols_case)
    end
    let(:certification) do
      create(:certification, vacols_id: appeal.vacols_id)
    end
    subject { certification.appeal }

    it "lazily loads the appeal for the certification" do
      expect(subject.vbms_id).to eq(appeal.vbms_id)
    end
  end

  context "#time_to_certify" do
    subject { certification.time_to_certify }

    context "when not completed" do
      it { is_expected.to be_nil }
    end

    context "when completed" do
      context "when not created (in db)" do
        let(:certification) do
          build(:certification, vacols_case: vacols_case)
        end

        it "is_expected to be_nil" do
          expect(subject).to eq nil
        end
      end

      context "when created" do
        before { certification.update!(completed_at: 1.hour.from_now) }

        it "returns the time since certification started" do
          expect(subject).to eq(1.hour)
        end
      end
    end
  end

  context ".complete!" do
    let(:certification) do
      create(:certification, :default_representative, vacols_case: vacols_case, hearing_preference: "VIDEO")
    end
    subject { certification.user_id }

    before do
      certification.async_start!
      certification.complete!(user.id)
    end

    it "should set the user id" do
      expect(subject).to eq(user.id)
    end
  end

  context ".find_by_vacols_id" do
    let(:vacols_id) { "1122" }
    let(:certification) do
      create(:certification, vacols_id: vacols_id)
    end

    subject { Certification.find_by_vacols_id(vacols_id) }

    context "when certification exists and it has not been cancelled before" do
      it "loads that certification " do
        expect(certification.id).to eq(subject.id)
      end
    end

    context "when certification exists and it has been cancelled before" do
      let!(:certification_cancellation) do
        CertificationCancellation.create(
          certification_id: certification.id,
          cancellation_reason: "test",
          email: "test@gmail.com"
        )
      end

      it "does not find one" do
        expect(subject).to eq nil
      end
    end
  end

  context ".find_or_create_by_vacols_id" do
    let(:vacols_id) { "1122" }
    subject { Certification.find_or_create_by_vacols_id(vacols_id) }

    context "when certification exists with that vacols_id and it has not been cancelled before" do
      before { @certification = Certification.create(vacols_id: vacols_id) }

      it "loads that certification " do
        expect(subject.id).to eq(@certification.id)
      end
    end

    context "when certification exists with that vacols_id and it has been cancelled before" do
      before do
        @certification = Certification.create(vacols_id: vacols_id)
        CertificationCancellation.create(certification_id: @certification.id, cancellation_reason: "test",
                                         email: "test@gmail.com")
      end

      it "creates a new certification" do
        expect(subject.id).to eq(Certification.where(vacols_id: vacols_id).last.id)
        expect(subject.id).not_to eq(@certification.id)
      end
    end

    context "when certification doesn't exist with that vacols_id" do
      it "creates a certification" do
        expect(subject.id).to eq(Certification.where(vacols_id: vacols_id).last.id)
      end
    end
  end

  context "#bgs_rep_address_found?" do
    subject { certification.bgs_rep_address_found? }

    it "returns true when bgs address is found" do
      expect(subject).to eq true
    end
  end

  context "#fetch_power_of_attorney!" do
    subject { certification }
    it "fetches the power of attorney from bgs and vacols" do
      certification.async_start!
      expect(subject.bgs_rep_city).to eq "SAN FRANCISCO"
      expect(subject.bgs_representative_type).to eq "Attorney"
      expect(subject.bgs_representative_name).to eq "Clarence Darrow"
      expect(subject.vacols_representative_name).to eq "The American Legion"
    end
  end

  context "#v2" do
    subject { Certification.v2 }

    before do
      Certification.create(v2: true)
      Certification.create(bgs_representative_type: "Attorney")
      Certification.create(bgs_representative_name: "Sir Alex F")
      Certification.create(vacols_representative_type: "Attorney")
      Certification.create(vacols_representative_name: "Jose Mou")
      Certification.create
    end

    it "returns only v2 certifications" do
      expect(Certification.all.count).to eq 6
      expect(subject.count).to eq 5
    end
  end

  context "#rep_name, #rep_type" do
    context "when the user indicates that poa matches across bgs and vacols" do
      let(:certification) do
        create(:certification, :default_representative, :poa_matches, vacols_case: vacols_case)
      end
      it "returns representative name from vacols" do
        expect(certification.rep_name).to eq("VACOLS_NAME")
      end
      it "returns representative type from vacols" do
        expect(certification.rep_type).to eq("VACOLS_TYPE")
      end
    end

    context "when the user indicates that poa does not match but bgs is correct" do
      let(:certification) do
        create(:certification, :default_representative, :poa_correct_in_bgs, vacols_case: vacols_case,
                                                                             hearing_preference: "VIDEO")
      end
      it "returns representative type from bgs" do
        expect(certification.rep_name).to eq("BGS_NAME")
      end
      it "returns representative name from bgs" do
        expect(certification.rep_type).to eq("BGS_TYPE")
      end
    end

    context "when bgs and vacols poa are both not correct" do
      let(:certification) do
        create(:certification, :default_representative, vacols_case: vacols_case, hearing_preference: "VIDEO")
      end
      it "returns representative type from bgs" do
        expect(certification.rep_name).to eq("NAME")
      end
      it "returns representative name from bgs" do
        expect(certification.rep_type).to eq("TYPE")
      end
    end
  end
end
