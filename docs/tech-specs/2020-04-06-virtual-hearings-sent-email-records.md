# Storing information about virtual hearings emails
**Drafter**: Tomas Apodaca

**Date**: April 6th, 2020

## Context
This tech spec proposes the back end changes necessary to store data for the feature described in [#13370](https://github.com/department-of-veterans-affairs/caseflow/issues/13370), "Display more info about sent Virtual Hearings emails". Hearing Coordinators need to see a history of the virtual hearing notification emails that Caseflow has sent, so that they can respond to inquiries and troubleshoot any issues.

## Approach
The spirit of the feature is to provide users a reliable record that they can use to reconstruct a history of the actions Caseflow has taken on their behalf. To fulfill that need, the approach described in this document stores enough information to give a future-proof record of sent emails.

For example, while we may maintain a link to the database record representing the person an email was sent to (via the Hearing record), we also store the email address as a string; this way, if the email address is ever edited in the database, we won't forget where the original email was sent.

## Non-goals
I've tried not to anticipate future needs too much; it might be nice to store the entire text of the email at some point, or to have this table record any kind of email we may someday want to send, but those aren't requirements of the feature.

## Implementation

We'll create a new model `SentHearingEmailEvents` and its corresponding table: `sent_hearing_email_events`, with (roughly) the following schema:

```ruby
  create_table "sent_hearing_email_events", force: :cascade do |t|
    t.bigint "hearing_id", comment: "Associated hearing"
    t.string "hearing_type", comment: "Hearing or LegacyHearing"
    t.string "external_message_id", comment: "The ID returned by the GovDelivery API when we send an email"
    t.string "recipient_role", comment: "The role of the recipient: veteran, representative, judge"
    t.string "email_type", comment: "The type of email sent: cancellation, confirmation, update"
    t.string "email_address", comment: "Address the email was sent to"
    t.integer "sent_by_id", comment: "User who initiated sending the email"
    t.datetime "sent_at", null: false, comment: "The date and time the email was sent"
    t.index ["hearing_type", "hearing_id"], name: "index_sent_hearing_email_events_on_hearing_type_and_hearing_id"
  end
```

New records will probably be created in the `Hearings::SendEmail` job when we successfully initiate the sending of an email. We may need to provide additional context to the job to accomplish this.

### Columns for message display

We can use these records to display information about a sent email like so:

**Sent To** _The field label of the email input field, either "Veteran Email" or "POA/Representative Email" or "VLJ Email"_

Get it by associating the value in `recipient_role` ('veteran', 'representative', or 'judge') with the appropriate field label.

**Email Address** _The email address the virtual hearing email was sent to_

This is stored in the `email_address` field.

**Date Sent** _The date Caseflow attempted to send the virtual hearing email_

The datetime object is stored in the `sent_at` field and can be formatted appropriately.

**Sent By** _The CSS ID of the user who initiated the sending of the email_

The user id of the sender is stored in `sent_by_id`; use that to look up the CSS ID.

### Additional columns

In addition, We'll store the type of message sent: `cancellation`, `confirmation`, or `update`; it's not required for the display, but will make things easier for engineers reconstructing a timeline.

We'll also store the unique ID returned by the GovDelivery API for each message in `external_message_id`; we can use this to query the API for the message's status.

## Open questions

1. For the same reasons, should we store a string representation of the hearing time that we sent in the email?
1. Would it be useful right now to have a `status` field representing the sent status of the email (for when we're able to collect that information)?
