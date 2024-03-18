# frozen_string_literal: true

describe "Basic SQL Snippet Library Test", :postgres do
  include SQLHelpers

  context "one Appeal exists" do
    let!(:appeal) { create(:appeal) }

    it "runs SQL" do
      result = execute_sql("basic_appeal")
      timestamp_fields = %w[created_at updated_at established_at receipt_date]

      aggregate_failures do
        expect(result).to match_array(hash_including(**appeal.attributes.except(*timestamp_fields)))

        result.first.slice(*timestamp_fields).each do |timestamp_field, timestamp_value|
          expect(timestamp_value.to_datetime.to_i).to eq(appeal[timestamp_field].to_datetime.to_i)
        end
      end
    end
  end

  context "one Appeal exists with 2f precision milliseconds" do
    let!(:appeal) { create(:appeal, established_at: Time.utc(2010, 3, 30, 5, 43, "25.12".to_r)) }

    it "rounds correctly" do
      expect_sql("basic_appeal").to match_array(hash_including("established_at" => appeal.established_at))
    end
  end
end
