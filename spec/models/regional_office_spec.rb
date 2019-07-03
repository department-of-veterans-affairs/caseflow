# frozen_string_literal: true

require "rails_helper"

describe RegionalOffice do
  let(:regional_office) { RegionalOffice.new(regional_office_key) }
  let(:regional_office_key) { nil }

  context ".find!" do
    subject { RegionalOffice.find!(regional_office_key) }

    context "valid regional office key" do
      let(:regional_office_key) { "RO43" }

      it do
        is_expected.to have_attributes(
          key: "RO43",
          station_key: "343",
          city: "Oakland",
          state: "CA",
          valid?: true
        )
      end
    end

    context "valid satellite office key" do
      let(:regional_office_key) { "SO43" }

      it do
        is_expected.to have_attributes(
          key: "SO43",
          city: "Sacremento",
          state: "CA",
          valid?: true
        )
      end
    end

    context "invalid regional office key" do
      let(:regional_office_key) { "RO747" }

      it "raises NotFoundError" do
        expect { subject }.to raise_error(RegionalOffice::NotFoundError)
      end
    end
  end

  context ".for_station" do
    subject { RegionalOffice.for_station("311") }

    it "returns regional office objects for each RO in the station" do
      expect(subject.length).to eq(2)
      expect(subject.first).to have_attributes(key: "RO11", city: "Pittsburgh")
      expect(subject.last).to have_attributes(key: "RO71", city: "Pittsburgh Foreign Cases")
    end
  end

  context ".facility_ids" do
    subject { RegionalOffice.facility_ids }
    let(:expected_ids) do
      %w[
        vba_301
        vba_402
        vha_402GA
        vha_402HB
        vba_304
        vba_405
        vba_373
        vba_306
        vba_306b
        vba_307
        vba_308
        vba_309
        vba_310
        vha_595
        vba_460
        vha_693
        vha_542
        vha_460HE
        vba_311
        vba_313
        vba_314
        vba_372
        vba_315
        vba_316
        vba_317
        vba_317a
        vba_318
        vba_319
        vba_320
        vc_0701V
        vc_0720V
        vc_0719V
        vha_626GF
        vba_321
        vba_321b
        vba_322
        vba_323
        vba_325
        vha_539
        vha_757
        vha_539
        vba_326
        vba_327
        vba_315
        vba_320
        vha_596
        vba_325b
        vha_539
        vha_657GJ
        vha_596GC
        vha_596GB
        vha_596GA
        vha_657GL
        vha_626GJ
        vc_0701V
        vha_626GC
        vha_538GB
        vha_603GF
        vha_596GD
        vha_657GP
        vha_657GO
        vha_626GH
        vc_0719V
        vc_0701V
        vc_0719V
        vba_328
        vha_636GF
        vba_329
        vba_330
        vba_335
        vha_607
        vha_676
        vha_585
        vha_676GA
        vha_618GM
        vha_676GD
        vha_676GC
        vha_607GE
        vha_607GD
        vha_607GC
        vha_695GD
        vha_695GA
        vha_695BY
        vha_618BY
        vha_676GE
        vha_556GD
        vha_618GH
        vha_585GC
        vha_618GE
        vba_331
        vba_333
        vha_636GF
        vha_438GC
        vha_636GJ
        vha_636GD
        vha_438GA
        vha_636GH
        vha_636
        vba_334
        vba_442
        vba_335
        vba_436
        vba_437
        vba_438
        vha_568
        vha_568A4
        vba_339
        vba_340
        vba_341
        vba_442
        vha_666GB
        vba_343
        vba_343f
        vba_344
        vba_345
        vba_346
        vha_663GC
        vha_663GE
        vba_348
        vha_668
        vha_687
        vc_0523V
        vba_347
        vha_668
        vha_660GA
        vha_668GB
        vba_348
        vba_347
        vha_653GB
        vha_648GA
        vha_692GA
        vha_687GC
        vha_653GA
        vba_346
        vha_692
        vba_349
        vba_349i
        vba_350
        vba_351
        vba_452
        vba_354
        vba_354a
        vba_355
        vba_358
        vba_459
        vc_0616V
        vba_459h
        vba_459i
        vc_0633V
        vc_0636V
        vc_0634V
        vha_459GH
        vba_460
        vba_362
        vha_671BY
        vha_740GB
        vba_463
        vba_373
        vba_405
        vba_377
      ]
    end

    it "returns all RO and AHL facility ids" do
      puts subject
      expect(subject).to match_array(expected_ids)
    end
  end

  context ".ro_facility_ids" do
    subject { RegionalOffice.ro_facility_ids }

    it "returns all RO facility ids" do
      expect(subject.count).to eq 58
    end
  end

  context ".ro_facility_ids_for_state for TX" do
    subject { RegionalOffice.ro_facility_ids_for_state("TX") }

    it "returns ro facility ids for Texas" do
      expect(subject).to match_array(%w[vba_349 vba_362])
    end
  end

  context ".find_ro_by_facility_id" do
    let(:ro_facility_id) { "vba_377" }
    let(:ahl_facility_id) { "vba_405" }

    it "returns RO ids for either RO or AHL facility ids" do
      expect(RegionalOffice.find_ro_by_facility_id(ro_facility_id)).to eq "RO77"
      expect(RegionalOffice.find_ro_by_facility_id(ahl_facility_id)).to eq "RO05"
    end
  end
end
