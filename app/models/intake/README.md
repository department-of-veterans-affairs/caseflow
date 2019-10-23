# Intake models

The Intake models are used for the process when a claims assistant is intaking an AMA form received by the veteran.

They are organized into subclasses, where logic specific to the type of intake can live:
- Intake
  - RAMP Review (does not have its own model)
    - RAMP Election Intake
    - RAMP Refiling Intake
  - Decision Review Intake (AMA)
    - Appeal Intake
    - Claim Review Intake
      - Supplemental Claim Intake
      - Higher Level Review Intake

All AMA reviews are called decision reviews.  Supplemental Claims and Higher Level Reviews are also part of a subcategory called claim reviews, because they result in claims in VBMS (for compensation and pension).  Appeals are processed in Caseflow.

When an intake is completed, it results in a "detail", which is also known as the review.
