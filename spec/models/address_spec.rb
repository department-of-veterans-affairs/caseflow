# frozen_string_literal: true

describe Address do
  context ".full_address" do
    let(:address_line_1) { "1118 Burlington Street" }
    let(:address_line_2) { nil }
    let(:address_line_3) { nil }
    let(:city) { "Holdrege" }
    let(:state) { "NE" }
    let(:zip) { "68949-1705" }
    let(:country) { nil }

    subject do
      Address.new(
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        address_line_3: address_line_3,
        city: city,
        state: state,
        zip: zip,
        country: country
      ).full_address
    end

    context "only address line 1 is populated" do
      it "returns expected address" do
        expect(subject).to eq("1118 Burlington Street, Holdrege NE 68949-1705")
      end
    end

    context "two address lines populated" do
      context "address_line_2 is populated" do
        let(:address_line_2) { "Mailing: P.O. Box 111111" }

        it "returns expected address" do
          expect(subject).to eq(
            "1118 Burlington Street Mailing: P.O. Box 111111, Holdrege NE 68949-1705"
          )
        end
      end

      context "address_line_3 is populated" do
        let(:address_line_3) { "Suite 6" }

        it "returns expected address" do
          expect(subject).to eq("1118 Burlington Street Suite 6, Holdrege NE 68949-1705")
        end
      end
    end

    context "all address lines populated" do
      let(:address_line_2) { "Associates of Blergh" }
      let(:address_line_3) { "Building Suite 1 and 2" }

      it "returns expected address" do
        expect(subject).to eq(
          "1118 Burlington Street Associates of Blergh Building Suite 1 and 2, Holdrege NE 68949-1705"
        )
      end
    end
  end
end
