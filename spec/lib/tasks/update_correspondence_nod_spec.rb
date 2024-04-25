# frozen_string_literal: true

describe "update_correspondence_nod" do
  include_context "rake"

  describe "correspondence:update_nod" do
    before do
      (1..3).map { create(:correspondence) }
    end

    context "rake task is ran" do
      it "updates the update_nod of correspondence with package document type name as 10182" do
        expect(Correspondence.pluck(:nod)).to eq([false, false, false])
        package_document_type = Correspondence.last.package_document_type
        package_document_type.update!(name: "10182")
        Rake::Task["correspondence:update_nod"].invoke
        expect(Correspondence.last.nod).to eq(true)
      end
    end
  end
end
