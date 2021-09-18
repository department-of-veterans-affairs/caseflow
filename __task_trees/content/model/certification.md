
# Caseflow Certification
* [Certification tables diagram](https://dbdiagram.io/d/5fc6a0143a78976d7b7e2059)

## Certifications
Caseflow Certification ensures accurate Veteran and appeal information are transferred from the Veterans Benefits Administration (VBA) to the Board of Veterans Appeals (BVA). The Certifications table facilitates this process by ensuring necessary documentation has been submitted with an Appeal and is consistent between [VBMS](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data%3A-where-and-why) and [VACOLS](https://github.com/department-of-veterans-affairs/caseflow/wiki/VACOLS-DB-Schema). Caseflow Certification is also responsible for verifying the veteran's representation and hearings request are accurate and ready to be sent to the Board.
* `poa_correct_in_bgs`
* `poa_correct_in_vbms`
* `nod_matching`
* `soc_matching`
* `already_certified`

## Form8s
Once an Appeal has been certified, the information on a Form8 form will be sent to the Board and the representation and hearing information will be updated in VACOLS accordingly.
* `hearing_requested`
* `hearing_held`: `nil` if `hearing_requested` set to `No`
* `certification_date`
* `soc_date`
* `power_of_attorney` information pulled from [BGS](https://github.com/department-of-veterans-affairs/caseflow/wiki/Data%3A-where-and-why)

## LegacyAppeals
The [LegacyAppeals](https://github.com/department-of-veterans-affairs/caseflow/wiki/Intake-Data-Model#legacyappeal) table stores records of non-AMA appeals, appeals which originated in VACOLS, that are worked by Caseflow.
* `changed_request_type` is either the value of `R` representing a virtual hearing or `V` representing a video hearing. Those are the only two options when updating a hearing request
* `vbms_id` is either the Veteran's file number + "C" or the Veteran's SSN + "S"

## CertificationCancellations
The CertificationCancellations table stores instances of cancelled certifications.
* `cancellation_reason` can be one of the following:
   * `VBMS and VACOLS dates didn't match and couldn't be changed`
   * `Missing document could not be found`
   * `Pending FOIA request`
   * `Other`

## Relationships
In the diagram below you will see the `certifications` table's `id` is stored on the `certification_cancellations` table as well as the `form8s` table.

The `form8s` table connects with the `certifications` table through the `certification_date`, `representative_name`, `representative_type`, and `vacols_id`, which also connects it with the `legacy_appeals` table. It is connected with a Veteran by storing the `veteran_file_number`.

<img src="https://user-images.githubusercontent.com/63597932/116123748-6468f180-a691-11eb-86bd-9dc6012f7be9.png">
