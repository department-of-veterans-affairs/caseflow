describe AppealAlert do
  let(:appeal) do
    Generators::Appeal.build(
      form9_date: nil
    )
  end
  let(:alert) { AppealAlert.new(appeal: appeal, type: type) }
  let(:type) { :form9_needed }

  context "#to_hash" do
    subject { alert.to_hash }
    context "form9_needed alert" do
      it "has a type and details" do
        expect(subject[:type]).to eq(:form9_needed)
        expect(subject[:details][:due_date]).to eq(appeal.form9_due_date)
      end
    end

    context "unknown alert" do
      let(:type) { :not_a_real_alert }

      it "has an empty details hash" do
        expect(subject[:details]).to eq({})
      end
    end
  end
end