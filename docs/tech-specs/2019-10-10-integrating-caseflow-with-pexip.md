This document was moved from [appeals-team](https://github.com/department-of-veterans-affairs/appeals-team/blob/main/Project%20Folders/Caseflow%20Projects/Hearings/Telehearings/tech-specs/Integrating%20Caseflow%20with%20Pexip.md).

# Integration with Pexip for Virtual Hearings

## Context

"Virtual hearings" is an initiative by BVA to introduce an additional way to conduct hearings through video conferencing. Virtual hearings will allow a veteran to attend a hearing from the convenience of their own personal device instead of requiring them to travel to their nearest regional office.

A hearing coordinator should be able to schedule a virtual hearing between the veteran, judge, and/or veteran's representative using Caseflow. Caseflow will leverage Pexip, the existing video conferencing platform that is deployed within the VA internal network, to support video conferencing. Pexip exposes an API that allows external applications to create and modify conferences and participants. This document lays out how Caseflow will interact with the Pexip API to create and schedule a video conference that the veteran, judge, and/or veteran's representative will be able to attend.

There is an additional component to email the participants of the conference that can not be handled through the Pexip API and will require some additional planning. The implementation of that solution will not be covered in this document.

### Related Tickets

  - [Epic](https://app.zenhub.com/workspaces/caseflow-5915dd178f67e20b5553ba0c/issues/department-of-veterans-affairs/caseflow/11132)
  - [Tech Spec](https://app.zenhub.com/workspace/o/department-of-veterans-affairs/caseflow/issues/12012)
  - [Implementation](https://app.zenhub.com/workspace/o/department-of-veterans-affairs/caseflow/issues/11730)

### Resources

  - [Pexip homepage](https://www.pexip.com)
  - [Pexip documentation](https://docs.pexip.com/index.htm)
  - [Pexip management API documentation](https://docs.pexip.com/api_manage/management_intro.htm)
  - [Pexip pins and hosts vs. guests](https://docs.pexip.com/admin/pins_hosts_guests.htm)
  - [Pexip personalized URL](https://support.pexip.com/hc/en-us/articles/200872727?input_string=webapp)
  - [Pexip browser support](https://docs.pexip.com/admin/interoperability.htm)
  - [Slack Thread on Deployment](https://dsva.slack.com/archives/CAM9FJ85P/p1570459327417500)
  - [Mapping Host to IP](https://github.com/department-of-veterans-affairs/appeals-deployment/blob/2b67911264124e41e887cf810f735c0d1eb8c493/ansible/vars/va-services.yml)

## Overview

To support the BVA's video conferencing initiative, Caseflow will need to be able to manage Pexip conferences from creation to deletion using the Pexip API.

When a hearing coordinator changes an existing hearing to a virtual hearing, Caseflow will initialize a row in a new virtual hearings table, and start a job that is responsible for creating a conference in Pexip. Virtual hearings will be scheduled alongside video hearings on the same docket initially, but in the future they will be scheduled separately on their own docket.

If the Pexip conference is created successfully, Caseflow will populate the initialized database row with the information necessary for sending an invitation email to the participants of the conference (the veteran, the judge, and the veteran's representative).

The backend will support changing the email addresses of the conference participants and cancelling or changing a scheduled hearing. These changes will be captured in the virtual hearings table (not in Pexip), and can be used to retrigger jobs for notifying the participants of the status of their hearing.

After a hearing is held or cancelled, Caseflow is responsible for deleting the conference in Pexip. Caseflow will have a scheduled recurring job that will search the database for completed hearings with Pexip conferences and issue a delete command to the Pexip API.

We anticipate that the implementation of the asynchronous jobs to create and delete the Pexip conference can happen in parallel with the implementation of the Pexip API client, and the deployment scripts.

There are still some unknowns about performance of the Pexip API in production, and how we plan on retrying jobs that continuously fail due to a bug in the code or some other recurring issue.

## Implementation

### API

Pexip offers a suite of API endpoints to manage calls or configure their service. We plan on using their management API, which provides routes for creating, updating, and deleting video conferences that users can join. This section covers what we plan on populating Pexip with, and expectations around response codes for various API endpoints.

#### Access

The Pexip API uses [basic](https://en.wikipedia.org/wiki/Basic_access_authentication) authentication. Credentials must be provisioned by an administrator from the government, and there will be separate credentials for the developer and production environments.

Since the Pexip management node is only accessible from the VA's internal network, commands must be issued from a device with the appropriate level of access.

#### Conference

The main resource we are going to be handling from Caseflow is a Pexip conference. Pexip provides a RESTful API to create, edit, and delete conferences. Creating a conference from the Pexip API generates a **virtual meeting room (VMR)** that users can subsequently join given the appropriate URL.

##### Fields

The following table shows how we are planning to populate the conference object when creating it. Additional context about complex field values are supplied where appropriate.

|            Field             |      Type      |             Value                |
|------------------------------|----------------|----------------------------------|
| [aliases](#aliases)          | Array          | `BVA` Prefix + 7 digit id        |
| allow_guests                 | Boolean        | `true`                           |
| automatic_participants       | Array          | Blank or null                    |
| call_type                    | Enum (String)  | Default (`"video"`)              |
| creation_time                | DateTime       | Auto-generated                   |
| [description](#description)  | String         | Debug + `"Created by Caseflow"`  |
| enable_chat                  | Enum (String)  | `"yes"`                          |
| enable_overlay_text          | Boolean        | `true`                           |
| force_presenter_into_main    | Boolean        | `true`                           |
| gms_access_token             | String         | Blank or null                    |
| [guest_pin](#pin)            | String         | Random 4 digit number (Guest)    |
| guest_view                   | Enum (String)  | **TBD**                          |
| guests_can_present           | Boolean        | Default (`true`)                 |
| host_view                    | Enum (String)  | **TBD**                          |
| id                           | Number         | Auto-generated                   |
| [ivr_theme](#ivr_theme)      | ID (String)    | ID of VA-branded theme           |
| match_string                 | String         | Blank or null                    |
| max_callrate_in              | Number         | Blank or null                    |
| max_callrate_out             | Number         | Blank or null                    |
| mssip_proxy                  | ?              | Blank or null                    |
| mute_all_guests              | Boolean        | **TBD**                          |
| [name](#name)                | String         | `BVA` prefix + unique identifier |
| participant_limit            | Number         | Blank or null                    |
| [pin](#pin)                  | String         | Random 4 digit number (Host)     |
| post_replace_string          | String         | Blank or null                    |
| primary_owner_email_address  | String         | Blank or null                    |
| replace_string               | String         | Blank or null                    |
| resource_uri                 | String         | Auto-generated                   |
| scheduled_conferences        | Array          | Blank or null                    |
| scheduled_conferences_count  | Number         | Auto-generated                   |
| service_type                 | Enum (String)  | Default (`conference`)           |
| sync_tag                     | String         | Auto-generated                   |
| system_location              | String         | Blank or null                    |
| tag                          | String         | `"CASEFLOW"`                     |
| teams_proxy                  | ?              | Blank or null                    |
| two_stage_dial_type          | Enum (String)  | Default (`regular`)              |

###### aliases

Caseflow will be provided with a range of 7-digit numbers to use as IDs. We should select a number from within this range, and use it in our aliases. If the end of this range is ever reached, we can start selecting numbers from the beginning again.

The numeric ID must be 7-digits to support a future initiative to allow veterans to call into a virtual hearing using an 800 number. The 7-digit number following the 800 area code would route a participant's call to a Pexip conference with the same alias, and they would join as an audio-only participant. While we currently do not know how the VA plans on implementing this, Pexip seems to support this workflow through [phone number to conference alias mappings](https://docs.pexip.com/admin/integrate_pstn.htm).

In one of our aliases, we were asked to include `BVA` for analytics purposes.

The three aliases we should provide are as follows:

  - `"BVA#{7-digit id}"`
    - Example: `"BVA1234567"`
  - `"BVA#{7-digit id}.#{domain}"`
    - Example: `"BVA1234567.care.va.gov"`
  - `"#{7-digit id}"`
    - Example: `"1234567"`

###### description

The description field is an internal field that can be used to store context about the conference. Most of the existing services that interact with the Pexip API populate this with the description: `"Created by <XYZ service>"`. We can provide a similar description, and also populate this with debugging information that might be helpful in production. There is a 250 character limit on the description field, so we should be mindful of that.

###### ivr_theme

The VA has conference themes in Pexip that we can leverage using this field. We can populate this with the ID of an existing VA-branded theme.

*3/4/2020 Edit*

The `ivr_theme` field needs to be populated with a theme path. The theme path can be obtained using the Pexip API:

```
curl \
  -Lv \
  --resolve '<MANAGEMENT_NODE_HOST>:443:<MANAGEMENT_NODE_IP>' \
  --user '<USERNAME>:<PASSWORD>' \
  https://<MANAGEMENT_NODE_HOST>/api/admin/configuration/v1/ivr_theme/<THEME ID>/
```

###### name

The name field is a required field that must be unique among existing conferences in Pexip. The name should include the `BVA` prefix for VA analytics purposes. We should be able to populate the `name` field with the same 7-digit identifier we use as one of the [aliases](#aliases).

We should never have duplicate names because we are planning on deleting conferences for hearings that have already occurred (the `name` of a deleted conference becomes reusable for future conferences). We are also assuming that the number of simultaneous virtual hearings will never exceed the number of 7-digit identifiers the VA provides.

###### pin

We have to randomly generate both the guest pin and the host pin. If the pins have differing lengths, we should terminate them with a `#` character.

The pin can be auto-filled if it's included in the user-facing URL for the video conferencing web application. We are planning on having these both be the minimum number of digits (4) because we don't see any benefits from making it longer.

##### Responses

Below are some responses that we observed while testing the Pexip API.

###### Successful

| Method | Code  |                    Description                   |
|--------|-------|--------------------------------------------------|
| GET    |  200  | Successful                                       |
| POST   |  201  | Successfully created                             |
| PATCH  |  202  | Successfully updated                             |
| DELETE |  204  | Successfully deleted                             |

###### Errors

| Method | Code  |                    Description                   |
|--------|-------|--------------------------------------------------|
| *      |  501  | Not implemented or invalid method for route      |
| POST   |  400  | Conference already exists                        |
| *      |  400  | Generic bad request, no specific error           |
| *      |  404  | Not found                                        |
| *      |  405  | Method not allowed                               |

##### Examples

Provided below are some examples to interact with the conference API route using `curl`. Since the management node is only accessible from the VA internal network, these commands should be executed from a server in UAT or production.

**🚨 The trailing slashes are necessary!**

###### GET

```
$ curl \
  -Lv \
  --resolve '<MANAGEMENT_NODE_HOST>:443:<MANAGEMENT_NODE_IP>' \
  --user '<USERNAME>:<PASSWORD>' \
  https://<MANAGEMENT_NODE_HOST>/api/admin/configuration/v1/conference/
```
###### POST

```json
{
  "allow_guests": true,
  "description": "TESTING DESCRIPTION",
  "enable_chat": "yes",
  "enable_overlay_text": true,
  "guest_pin": "1234",
  "guest_view": "one_main_seven_pips",
  "guests_can_present": true,
  "host_view": "two_mains_twentyone_pips",
  "mute_all_guests": false,
  "name": "CASEFLOW_TEST_1",
  "pin": "4321",
  "tag": "CASEFLOW"
}
```

```
$ curl \
  -Lv \
  --resolve '<MANAGEMENT_NODE_HOST>:443:<MANAGEMENT_NODE_IP>' \
  --user '<USERNAME>:<PASSWORD>' \
  -d @payload.json \
  -H 'Content-Type: application/json' \
  https://<MANAGEMENT_NODE_HOST>/api/admin/configuration/v1/conference/
```

###### PATCH

```json
{
  "description": "a new description"
}
```

```
curl \
  -Lv \
  --resolve '<MANAGEMENT_NODE_HOST>:443:<MANAGEMENT_NODE_IP>' \
  --user '<USERNAME>:<PASSWORD>' \
  -d @update.json \
  -H 'Content-Type: application/json' \
  -X PATCH \
  https://<MANAGEMENT_NODE_HOST>/api/admin/configuration/v1/conference/<CONFERENCE ID>/
```

###### DELETE

```
curl \
  -Lv \
  --resolve '<MANAGEMENT_NODE_HOST>:443:<MANAGEMENT_NODE_IP>' \
  --user '<USERNAME>:<PASSWORD>' \
  -X DELETE \
  https://<MANAGEMENT_NODE_HOST>/api/admin/configuration/v1/conference/<CONFERENCE ID>/
```

### Association Between Caseflow Hearing and Pexip Conference

In order to reference the Pexip conference after it's created from Caseflow, we should create an additional `virtual_hearings` table that associates a Caseflow hearing to a conference in Pexip. The table could also be leveraged to store state regarding whether participants have been notified or whether or not the conference was successfully created. Below is a preliminary schema for this associated table:

|           Column          |     Type    |                          Description                          | Index |
|---------------------------|-------------|---------------------------------------------------------------|-------|
| hearing_id                | Foreign Key | Polymorphic association to hearing                            |   Y   |
| hearing_type              | Foreign Key | Polymorphic association to hearing                            |   Y   |
| conference_id             | Foreign Key | Pexip id for a conference                                     |   Y   |
| alias                     | String      | Conference alias that Caseflow will generate                  |       |
| guest_pin                 | Number      | Guest pin number that Caseflow will generate                  |       |
| host_pin                  | Number      | Host pin number that Caseflow will generate                   |       |
| veteran_email             | String      | The veteran's email address                                   |       |
| representative_email      | String      | The representative's email address                            |       |
| judge_email               | String      | The judge's email address                                     |       |
| veteran_email_sent        | Boolean     | `true` if the invitation email was sent to the veteran        |       |
| judge_email_sent          | Boolean     | `true` if the invitation email was sent to the judge          |       |
| representative_email_sent | Boolean     | `true` if the invitation email was sent to the representative |       |
| conference_deleted        | Boolean     | `true` if the conference was deleted from Pexip               |       |
| [status](#status)         | String      | Indicates the state of the conference                         |       |

#### Status

We plan on having three statuses to indicate the state of the virtual hearing:

|   State   |                                      Description                                          |
|-----------|-------------------------------------------------------------------------------------------|
| pending   | Initial status for a virtual hearing. Indicates the Pexip conference does not exist yet   |
| active    | Indicates that the Pexip conference was created                                           |
| cancelled | Indicates that the hearing was cancelled, and the Pexip conference needs to be cleaned up |

### Creating a Conference

#### Option A: Creating a Conference Asynchronously with a Job

There are two asynchronous approaches we can take to schedule the creation of a conference in Pexip:

  1. We can create a scheduled job which will search for all hearings which have been scheduled and will make one or more bulk requests to create conferences for those hearings.

  2. We can create a single job for each hearing when it is switched to a virtual hearing. That job would initiate the request to Pexip to create the conference.

After each job completes successfully, the created conferences will be mapped to their respective hearings in the new `virtual_hearings` table in Caseflow.

In the event of an error, jobs will [retry until they succeed](#open-questions), but may retry at different intervals depending on the error message returned by the Pexip API.

##### Pros:

  - We can create multiple conferences at once using a bulk request to Pexip API as Pexip recommends for performance purposes (for option 1).
  - The hearing coordinator is not responsible for trying to setup a conference again in the event of a failure.
  - From the user's perspective, this approach might appear faster because it does not depend on the performance of the Pexip API.
  - We can leverage the asynchronous job for this approach to also send out invitation emails to the judge, veteran, and veteran's representative.

##### Cons:

  - The hearing coordinator will not be notified immediately if the request to the API fails.
  - If there is a bug in the application code, there may be a condition where the job will never succeed and continues to use resources on the server.
  - Asynchronous code is harder to test, debug, and implement.
  - The user might be uncertain whether or not the conference was actually scheduled because they do not have access to the conference URL immediately.

#### Option B: Creating a Conference On-Demand

We can create the conference when the hearing coordinator schedules the virtual hearing by making a single request to the Pexip API. This request would happen in the controller when the hearing coordinator changes a hearing to a virtual hearing.

##### Pros:

  - The hearing coordinator is notified immediately of success or failure.
  - Implementation, debugging, and testing of this approach will be easier.

##### Cons:

  - Making a single request instead of bulk request might be bad for [performance](https://docs.pexip.com/api_manage/using.htm#performance).
  - From the user's perspective, this approach might appear slower because it is dependent on the performance of the Pexip API.
  - If the Pexip API is down for an extended period of time, the hearing coordinator will have to come back and manually retry creating the virtual hearings.

#### Recommendation

We recommend implementing option A: "Creating a Conference Asynchronously with a Job" by creating an asynchronous job when the hearing coordinator switches a hearing to a virtual hearing. Even though option A is more difficult to implement, we think that it will create a better user experience because the hearing coordinator will not be blocked if there is ever an issue with the Pexip API. If there is messaging that will indicate to the hearing coordinator that this process will take additional time, we think that will alleviate some of the uncertainty around whether or not their action succeeded or not.

### Joining a Conference

The participants will be provided with a URL that, when clicked, will open the conference in their default browser.

The URL is in the format: `https://<address>/webapp/?conference=<alias>&name=<name>&bw=<bandwidth>&pin=<pin>&join=<join>&role=<role>`

Where:

  - `<address>` is the IP address or domain name of the Conferencing Node or reverse proxy
    - For dev env, the address will be `care.evn.va.gov`
    - For prod env, the address will be `care.va.gov`
  - `<alias>` is an [alias](#aliases) (`BVA#{7-digit id}`) for the VMR where the users will join
  - `<name>` is the same as [alias](#aliases)
  - `<brandwidth>` is the bandwidth in kbps, and can be any number between 256 and 1864
      - Default value is 576
  - `<pin>` is the randomly generated [Host or Guest PIN](#pin)
  - `<join>` is 1 if you want the participant to automatically join the conference, otherwise it is not present
      - Prefer to leave it as 1
  - `<role>` is either guest or host. We’d pre-fill this field depending on the participants i.e host for judges and guest for veterans and representatives

The URL must always include `https://<address>/webapp/?` But the remainder of the fields are optional. If a field is not specified in the URL, the user joining the conference will be asked to fill in the appropriate fields in a form before joining the conference.

We can pre-fill some or all of these fields and allow participants the participants to review and make changes before joining or we can format the URL so that the participants are taken straight into the conference. The latter is preferable as we will display a link on the hearing docket for judges and send emails containing the URL with detailed instructions to all participants.

### Deleting Conferences for Past Hearings

VMRs created by Caseflow should be torn down after the hearing date to prevent the accumulation of VMRs. Pexip does support a [global rule for conditionally ending conferences](https://docs.pexip.com/admin/automatically_terminate.htm) using their admin interface, but Caseflow's Pexip account does not have permissions to set this rule. Also, the conditions for ending a conference all involve the participants in the conference, which might not support Caseflow's needs.

VMRs also need to be removed if a hearing date is cancelled or moves to some alternative completed status that indicates that the hearing will no longer occur.

We could leverage the existing `CaseflowJob` class, and create a scheduled job that runs on a daily interval that makes a query to find virtual hearings where:

1. The date of the hearing is less than the current date
2. The status of the hearing is `cancelled` or `completed` and the `conference_deleted` flag is `false`

The job would delete these VMRs in Pexip, and mark the conference as deleted in the Caseflow database to prevent any subsequent jobs from issuing duplicate delete commands.

### Summary

When the hearing coordinator changes a hearing to a virtual hearing, a controller would create a row in the `virtual_hearings` table and kick off a job which takes the relevant data and attempts to create a conference. This job could also send emails to judges, veterans, and representatives.

We would have another async job which attempts to delete conferences which have already taken place or are no longer needed. For example: if a user changes the hearing back to a video hearing. In that case, this job could also email users informing them that their hearing has been changed.

## Deployment

| Environment | Hostname                            |
|-------------|-------------------------------------|
| Dev         | https://vasbyevnpmn.care.evn.va.gov |
| Production  | https://vapnnevnpmn.care.va.gov     |

### Environment Variables

To connect to the Pexip API, Caseflow will need to know the location of the Pexip API, and have the necessary credentials to interact with it, which varies between environments. The following variables should capture the necessary information to connect to the Pexip API:

  - PEXIP_MANAGEMENT_NODE_HOST
  - PEXIP_MANAGEMENT_NODE_PORT
  - PEXIP_CLIENT_HOST
  - PEXIP_USERNAME
  - PEXIP_PASSWORD

With our recommended approach for creating a Pexip conference, most of the interactions with the Pexip API should be initiated from an asynchronous job, so these variables would need to be defined in the worker environment.

### Hostname Resolution

The DNS server that's configured with the instances in production and UAT can't resolve the Pexip hostnames. We will need to include these mappings in our deployment scripts so we can use the provided hostnames in our code.

## Open Questions

  - The Pexip documentation outlines some performance considerations when interfacing with their API, and recommends a number of approaches to minimize the amount of load on the management node. While we don't expect there to be a large number of virtual hearings switched over simultaneously, we should find ways to monitor the performance of the API.

  - What is the best approach to implementing retry functionality for failed jobs given we expect some jobs to continuously fail?

  - If the Pexip conference can not be created, how do we notify the hearing coordinator that their attempt to schedule a virtual hearing failed? This notification could be significantly delayed from when they attempted to schedule the virtual hearing.
    - We can notify developers that a job failed through a Slack notification
