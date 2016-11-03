class PersistForm8Data < ActiveRecord::Migration
  def change
    # We're adding a table to store the Form 8 data for later analysis.
    # Fields that can be modified before certification have counterparts
    # prefixed by "_initial". We want this to do analysis on what fields
    # users manually edit.
    create_table :form8s do |t|
      t.string :vacols_id     # ID in VACOLS DB - not user modifiable
      t.string :_initial_appellant_name
      t.string :appellant_name # Person appealing distinct from veteran
      t.string :_initial_appellant_relationship
      t.string :appellant_relationship # Relationship to veteran
      t.string :file_number #ID in VBMS? - not user modifiable
      t.string :_initial_veteran_name
      t.string :veteran_name # FirstName LastName
      t.string :_initial_insurance_loan_number
      t.string :insurance_loan_number
      t.text :_initial_service_connection_for
      t.text :service_connection_for # How the claim is connected to service record
      t.datetime :_initial_service_connection_notification_date
      t.datetime :service_connection_notification_date
      t.text :_initial_increased_rating_for
      t.text :increased_rating_for
      t.datetime :_initial_increased_rating_notification_date
      t.datetime :increased_rating_notification_date
      t.text :_initial_other_for
      t.text :other_for
      t.datetime :_initial_other_notification_date
      t.datetime :other_notification_date
      t.string :_initial_representative_name
      t.string :representative_name
      t.string :_initial_representative_type
      t.integer :representative_type # enum ["Attorney" "Agent" "Organization" "Other"]
      t.string :_initial_representative_type_specify_other
      t.string :representative_type_specify_other
      t.string :_initial_power_of_attorney # Power of attorney blurb
      t.string :power_of_attorney # Enum: certification that valid POA is in another VA file
      t.string :_initial_power_of_attorney_file
      t.string :power_of_attorney_file
      t.string :_initial_agent_accredited
      t.string :agent_accredited
      t.boolean :_initial_form_646_of_record
      t.boolean :form_646_of_record
      t.string :_initial_form_646_not_of_record_explanation
      t.string :form_646_not_of_record_explanation
      t.boolean :_initial_hearing_requested
      t.boolean :hearing_requested
      t.boolean :_initial_hearing_held
      t.boolean :hearing_held
      t.boolean :_initial_hearing_transcript_on_file
      t.boolean :hearing_transcript_on_file
      t.string :_initial_hearing_requested_explanation
      t.string :hearing_requested_explanation
      t.boolean :_initial_contested_claims_procedures_applicable
      t.boolean :contested_claims_procedures_applicable
      t.boolean :_initial_contested_claims_requirements_followed
      t.boolean :contested_claims_requirements_followed
      t.datetime :_initial_soc_date
      t.datetime :soc_date
      t.string :_initial_ssoc_required
      t.integer :ssoc_required # enum  "Required and furnished"/"Not required"
      t.text :_initial_record_other_explanation, array: true
      t.text :record_other_explanation, array: true # One or more from a list of records to send to Veteran's Appeals
      t.text :_initial_remarks
      t.text :remarks
      t.string :certifying_office # Not user-modifiable
      t.string :certifying_username # Not user-modifiable
      t.string :_initial_certifying_official_name
      t.string :certifying_official_name
      t.string :_initial_certifying_official_title
      t.string :certifying_official_title
      t.datetime :certification_date # Not user-modifiable

      # Fields representing record types to be forwarded
      # to the Board of Veteran's Appeals. These are all integers
      # mostly for compatibility with code that existed before this
      # migration.
      t.integer :record_cf_or_xcf
      t.integer :record_inactive_cf
      t.integer :record_dental_f
      t.integer :record_r_and_e_f
      t.integer :record_training_sub_f
      t.integer :record_loan_guar_f
      t.integer :record_outpatient_f
      t.integer :record_hospital_cor
      t.integer :record_clinical_rec
      t.integer :record_x_rays
      t.integer :record_slides
      t.integer :record_tissue_blocks
      t.integer :record_dep_ed_f
      t.integer :record_insurance_f
      t.integer :record_other
    end
  end
end
