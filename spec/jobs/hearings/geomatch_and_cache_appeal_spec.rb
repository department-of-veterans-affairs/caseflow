# frozen_string_literal: true

describe Hearings::GeomatchAndCacheAppeal do
  include ActiveJob::TestHelper

  describe "#perform" do
    subject { Hearings::GeomatchAndCacheAppeal.new.perform(appeal_id: appeal.id) }

    context "with AMA appeal" do
      let(:appeal) { create(:appeal) }

      it "throws an error" do
        expect { subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    context "with Legacy appeal" do
      let(:vacols_case) { create(:case, :travel_board_hearing) }
      let(:closest_regional_office) { nil }
      let(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          closest_regional_office: closest_regional_office,
          vacols_case: vacols_case
        )
      end

      context "when closest regional office is not set" do
        it "sets the closest regional office field" do
          subject

          appeal.reload

          expect(appeal.closest_regional_office).to eq("RO17") # Default RO based on address geomatch
        end

        it "creates the cached appeal row" do
          subject

          expect(CachedAppeal.count).to eq(1)

          cached = CachedAppeal.first

          expect(cached.closest_regional_office_city).to eq("St. Petersburg")
          expect(cached.closest_regional_office_key).to eq("RO17") # Default RO based on address geomatch
          expect(cached.former_travel).to eq(false)
          expect(cached.hearing_request_type).to eq("Travel")
        end

        context "geomatching failed" do
          before { setup_geomatch_service_mock }

          it "re-raises error and does not created new cached appeal" do
            expect { subject }.to raise_error(StandardError)

            expect(CachedAppeal.count).to eq(0)
          end
        end
      end

      context "with existing closest regional office, but different from geomatch" do
        let(:closest_regional_office) { "RO02" }

        it "changes the closest regional office field" do
          subject

          appeal.reload

          expect(appeal.closest_regional_office).to eq("RO17") # RO02 => RO17
        end

        it "the cached appeal has the updated RO info" do
          subject

          expect(CachedAppeal.count).to eq(1)

          cached = CachedAppeal.first

          expect(cached.closest_regional_office_city).to eq("St. Petersburg")
          expect(cached.closest_regional_office_key).to eq("RO17") # RO02 => RO17
        end
      end

      context "with existing closest regional office, but geomatch fails" do
        let(:closest_regional_office) { "RO02" }

        before { setup_geomatch_service_mock }

        it "still creates cached appeal" do
          subject

          expect(CachedAppeal.count).to eq(1)

          cached = CachedAppeal.first

          expect(cached.closest_regional_office_city).to eq("Togus")
          expect(cached.closest_regional_office_key).to eq("RO02") # RO02 => RO17
        end
      end
    end
  end

  def setup_geomatch_service_mock
    service = GeomatchService.new(appeal: appeal)
    expect(GeomatchService).to(
      receive(:new)
        .with(appeal: appeal)
        .at_least(:once)
        .and_return(service)
    )
    expect(service).to(
      receive(:geomatch)
        .and_raise(StandardError.new("Fake Geomatch Error"))
    )
  end
end
