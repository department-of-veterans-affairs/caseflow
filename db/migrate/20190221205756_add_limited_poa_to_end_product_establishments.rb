class AddLimitedPoaToEndProductEstablishments < ActiveRecord::Migration[5.1]
  def change
    add_column :end_product_establishments, :limited_poa_code, :string, comment: "The limited Power of Attorney code, which indicates whether the claim has a POA specifically for this claim, which can be different than the Veteran's POA"
    add_column :end_product_establishments, :limited_poa_access, :string, comment: 'Indicates whether the limited Power of Attorney has access to view documents'
  end
end
