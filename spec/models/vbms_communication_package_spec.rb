# frozen_string_literal: true

describe VbmsCommunicationPackage, :postgres do
  let(:package) do
    VbmsCommunicationPackage.new(
      file_number: "329780002",
      comm_package_name: "test package name",
      copies: 1,
      document_mailable_via_pacman: VbmsUploadedDocument.new
    )
  end

  it "is valid with valid attributes" do
    expect(package).to be_valid
  end

  it "is not valid without a filenumber" do
    package.file_number = nil
    expect(package).to_not be_valid
    expect(package.errors[:file_number]).to eq(["can't be blank"])
  end

  it "is not valid without a communication package name" do
    package.comm_package_name = nil
    expect(package).to_not be_valid
    expect(package.errors[:comm_package_name]).to eq(
      [
        "can't be blank",
        "is too short (minimum is 1 character)",
        "is invalid"
      ]
    )
  end

  it "is not valid if communication package name exceeds 255 characters" do
    package.comm_package_name = "x" * 256
    expect(package).to_not be_valid
    expect(package.errors[:comm_package_name]).to eq(["is too long (maximum is 255 characters)", "is invalid"])
  end

  it "is not valid without a user friendly communication package name" do
    package.comm_package_name = "(test package name with parentheses)"
    expect(package).to_not be_valid
    expect(package.errors[:comm_package_name]).to eq(["is invalid"])
  end

  it "is not valid without a copies attribute" do
    package.copies = nil
    expect(package).to_not be_valid
    expect(package.errors[:copies]).to eq(["can't be blank", "is not a number"])
  end

  it "is not valid with less than one copy" do
    package.copies = 0
    expect(package).to_not be_valid
    expect(package.errors[:copies]).to eq(["must be greater than 0"])
  end

  it "is not valid with more than 500 copies" do
    package.copies = 500
    expect(package).to be_valid

    package.copies = 501
    expect(package).to_not be_valid
    expect(package.errors[:copies]).to eq(["must be less than 501"])
  end

  it "is not valid without an associated document mailable via pacman" do
    package.document_mailable_via_pacman = nil
    expect(package).to_not be_valid
    expect(package.errors[:document_mailable_via_pacman]).to eq(["must exist"])
  end
end
