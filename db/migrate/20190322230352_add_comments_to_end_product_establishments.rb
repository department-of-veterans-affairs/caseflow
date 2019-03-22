class AddCommentsToEndProductEstablishments < ActiveRecord::Migration[5.1]
  def change
    change_table_comment(:end_product_establishments, "Keeps track of End Products that need to be established for AMA Decision Review Intakes, when they are successfully established, and updates on the End Product's status.")

    change_column_comment(:end_product_establishments, :benefit_type_code, "The benefit_type_code is 1 if the Veteran is alive, and 2 if the Veteran is deceased. Not to be confused with benefit_type, which is unrelated.")

    change_column_comment(:end_product_establishments, :claim_date, "The claim_date for End Products established is set to the receipt date of the form.")

    change_column_comment(:end_product_establishments, :claimant_participant_id, "The participant ID of the claimant submitted on the End Product.")

    change_column_comment(:end_product_establishments, :code, "The end product code, which determines the type of end product that is established. For example, it can contain information about whether it is rating, nonrating, compensation, pension, created automatically due to a Duty to Assist Error, and more.")

    change_column_comment(:end_product_establishments, :committed_at, "Timestamp indicating other actions performed as part of a larger atomic operation containing the end product establishment, such as creating contentions, are also complete.")

    change_column_comment(:end_product_establishments, :development_item_reference_id, "When a Veteran requests an informal conference with their Higher Level Review, a tracked item is created. This stores the ID of the of the tracked item, it is also used to indicate the success of creating the tracked item.")

    change_column_comment(:end_product_establishments, :doc_reference_id, "When a Veteran requests an informal conference, a claimant letter is generated. This stores the document ID of the claimant letter, and is also used to track the success of creating the claimant letter.")

    change_column_comment(:end_product_establishments, :established_at, "Timestamp for when the End Product was established.")

    change_column_comment(:end_product_establishments, :last_synced_at, "The time that the status of the End Product was last synced with BGS. Once an End Product is cleared or canceled, it will stop being synced.")

    change_column_comment(:end_product_establishments, :modifier, "The end product modifier. For Higher Level Reviews, the modifiers range from 030-039. For Supplemental Claims, they range from 040-049. The same modifier cannot be used twice for an active end product per Veteran.  Once an End Product is no longer active, the modifier can be used again.")

    change_column_comment(:end_product_establishments, :payee_code, "The payee_code of the claimant submitted for this End Product.")

    change_column_comment(:end_product_establishments, :reference_id, "The claim_id of the End Product, which is stored after the End Product is successfully established in VBMS")

    change_column_comment(:end_product_establishments, :source_id, "The ID of the Decision Review that the end product establishment is connected to.")

    change_column_comment(:end_product_establishments, :source_type, "The type of Decision Review that the End Product Establishment is for, for example HigherLevelReview.")

    change_column_comment(:end_product_establishments, :station, "The station ID of the End Product's station.")

    change_column_comment(:end_product_establishments, :synced_status, "The status of the End Product, which is synced by a job. Once and End Product is Cleared (CLR) or (CAN), it stops getting synced because the status will no longer change")

    change_column_comment(:end_product_establishments, :user_id, "The ID of the user who performed the Decision Review Intake connected to this End Product Establishment.")

    change_column_comment(:end_product_establishments, :veteran_file_number, "A veteran's file number. This is used to associate an EP with a speciifc veteran. File numbers do not always individually identify veterans. In the future should switch to veteran participant id")
  end
end
