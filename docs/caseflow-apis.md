# Caseflow APIs

## Overview

Caseflow provides HTTP APIs for consumption by external services. Generally these APIs expose
Caseflow data in a read-only pattern via specific queries, although some API endpoints do allow for modifying
Caseflow data (e.g. Caseflow Jobs, IDT, Decision Review API).

All API responses are in JSON format.

All API requests prefer to keep sensitive PII out of URLs and instead inside HTTP headers. This helps prevent
leaking PII into logs and unauthorized communication channels.

Only actively maintained APIs are documented here. See the Git log history of this document for details.

## API Keys

All API requests require a valid API key token, which is passed in the `Authorization` HTTP header. See the `curl`
examples below for the proper syntax.

If you need an API key, you can request one via [YourIT](https://yourit.va.gov/).

If you are a Caseflow administrator, you can create a key in the Caseflow Rails console:

```bash
irb> api_key = ApiKey.create!(consumer_name: "Some Application")
irb> api_key.key_string
# the key string is what you pass in the HTTP header
```

---
Most, [but not all](#other-apis--endpoints) APIs / endpoints are scoped under a version number: [v1](#v1), [v2](#v2), or [v3](#v3).
# _v1_
The version 1 namespace includes the [Caseflow Jobs](#caseflow-jobs) API, and the [IDT](#idt) API.

## Caseflow Jobs

You may `POST /api/v1/jobs` with the `job_type` body parameter in order to create a new Shoryuken-based job.
The list of job types available is in
[the controller](https://github.com/department-of-veterans-affairs/caseflow/blob/master/app/controllers/api/v1/jobs_controller.rb#L5).

```bash
% curl -XPOST -H 'Authorization: Token your-sekrit-key' \
       https://appeals.cf.ds.va.gov/api/v1/jobs -d 'job_type=sync_intake'
```

On success you would receive a response with HTTP code `200` and body like:

```json
{"success":true, "job_id":"5beec69d-a777-497e-b65d-2ac488b507ba"}
```

On failure you would receive a response with HTTP code `422` and body like:

```json
{"error_code":"Unable to start unrecognized job"}
```

or if the API key was missing or not found, a HTTP code `401` and body like:

```json
{"status":"unauthorized"}
```

## IDT

The Interactive Decision Template (IDT) is a set of Microsoft Word macros that allow for authoring and publishing
BVA decisions natively in Word. The IDT API allows Word to pre-populate the document with Veteran data from
VACOLS/Caseflow.

There are several endpoints available in the IDT API.

#### `GET /idt/api/v1/token`

Returns a one-time key and token for subsequent requests.

```bash
% curl -H 'Authorization: Token your-sekrit-key' https://appeals.cf.ds.va.gov/idt/api/v1/token
```

On success returns a `200` HTTP code and a body like:

```json
{
   "one_time_key" : "a-long-128-byte-string",
   "token" : "another-long-128-byte-string"
}
```

#### `GET /idt/auth?one_time_key=:your-one-time-key`

Activates an IDT session based on a one-time key. The default IDT session is 7 days.

**NOTE** this is typically done via a web browser since it requires
an active authenticated Caseflow browser session to link with a Caseflow user account.

```bash
% curl -H 'Authorization: Token your-sekrit-key' \
       https://appeals.cf.ds.va.gov/idt/auth?one_time_key=a-long-128-byte-string
```

On success returns a `200` HTTP code and body like:

```json
{"message":"Success!"}
```

On error returns a `400` code with an error message like:

```json
{"message":"Invalid key."}
```

Once the IDT session is activated, the `token` is passed in subsequent requests.

#### `GET /idt/api/v1/appeals`

```bash
% curl -H 'TOKEN: your-idt-token' \
       -H 'FILENUMBER: veteran-file-number' \
       https://appeals.cf.ds.va.gov/idt/api/v1/appeals
```

#### `GET /idt/api/v1/appeals/:appeal_id`

```bash
% curl -H 'TOKEN: your-idt-token' \
       https://appeals.cf.ds.va.gov/idt/api/v1/appeals/uuid_or_vacols_id
```

#### `POST /idt/api/v1/appeals/:appeal_id/outcode`

#### `POST /idt/api/v1/appeals/:appeal_id/upload_document`

#### `GET /idt/api/v1/judges`

```bash
% curl -H 'TOKEN: your-idt-token' \
       https://appeals.cf.ds.va.gov/idt/api/v1/judges
```

#### `GET /idt/api/v1/user`

```bash
% curl -H 'TOKEN: your-idt-token' \
       https://appeals.cf.ds.va.gov/idt/api/v1/user
```

#### `GET /idt/api/v1/veterans`

```bash
% curl -H 'TOKEN: your-idt-token' \
       -H 'FILENUMBER: veteran-file-number' \
       https://appeals.cf.ds.va.gov/idt/api/v1/veterans
```

# _v2_
The version 2 namespace includes the [va.gov Appeals Status](#vagov-appeals-status) API, and the [VETText / Hearings](#vettext--hearings) API.

## va.gov Appeals Status

The Appeals Status feature of va.gov allows Veterans to see details about their cases.

[Additional documentation is available](https://github.com/department-of-veterans-affairs/caseflow/wiki/Appeal-Status-API).

You may `GET /api/v2/appeals` with the Veteran Social Security Number (SSN) in the `ssn` HTTP header
and a `source` string of your choosing.

```bash
% curl -H 'Authorization: Token your-sekrit-key' \
       -H 'ssn: 987654321' \
       -H 'source: white house hotline' \
       https://appeals.cf.ds.va.gov/api/v2/appeals
```

On success you would receive a `200` HTTP code and a body like:

```json
{
   "data" : [
      {
         "attributes" : {
            "active" : false,
            "alerts" : [],
            "aoj" : "vba",
            "appealIds" : [
               "HLR2"
            ],
            "description" : "1  issue",
            "events" : [
               {
                  "date" : "2018-04-01",
                  "type" : "hlr_request"
               },
               {
                  "date" : "2019-06-04",
                  "type" : "hlr_other_close"
               }
            ],
            "evidence" : [],
            "incompleteHistory" : false,
            "issues" : [],
            "location" : "aoj",
            "programArea" : null,
            "status" : {
               "details" : {},
               "type" : "hlr_closed"
            },
            "updated" : "2019-06-05T15:37:37-04:00"
         },
         "id" : "HLR2",
         "type" : "higherLevelReview"
      },
      {
         "attributes" : {
            "active" : true,
            "alerts" : [],
            "aod" : true,
            "aoj" : "vba",
            "appealIds" : [
               "2760964"
            ],
            "description" : "Service connection, pancreatitis",
            "docket" : null,
            "events" : [
               {
                  "date" : "2014-01-29",
                  "type" : "claim_decision"
               },
               {
                  "date" : "2014-11-01",
                  "type" : "nod"
               },
               {
                  "date" : "2015-08-19",
                  "type" : "soc"
               },
               {
                  "date" : "2015-09-22",
                  "type" : "form9"
               },
               {
                  "date" : "2018-09-25",
                  "type" : "ssoc"
               },
               {
                  "date" : "2018-10-03",
                  "type" : "certified"
               },
               {
                  "date" : "2019-02-08",
                  "type" : "bva_decision"
               },
               {
                  "date" : "2019-05-27",
                  "type" : "hearing_held"
               }
            ],
            "evidence" : [],
            "incompleteHistory" : false,
            "issues" : [
               {
                  "active" : true,
                  "date" : "2019-02-08",
                  "description" : "Service connection, pancreatitis",
                  "diagnosticCode" : "7347",
                  "lastAction" : "remand"
               }
            ],
            "location" : "aoj",
            "programArea" : "compensation",
            "status" : {
               "details" : {
                  "issues" : [
                     {
                        "description" : "Service connection, pancreatitis",
                        "disposition" : "remanded"
                     }
                  ],
                  "remand_timeliness" : [
                     16,
                     29
                  ]
               },
               "type" : "remand"
            },
            "type" : "original",
            "updated" : "2019-06-05T15:37:37-04:00"
         },
         "id" : "2760964",
         "type" : "legacyAppeal"
      }
   ]
}
```

If you provide an invalid SSN, the response would be a `422` HTTP code and a body like:

```json
{
   "errors" : [
      {
         "detail" : "Please enter a valid 9 digit SSN in the 'ssn' header",
         "status" : "422",
         "title" : "Invalid SSN"
      }
   ]
}
```

Other invalid request parameters would receive similarly formatted error responses.

## VETText / Hearings

The Hearings API returns all the hearings scheduled for a given day.

```bash
% curl -H 'Authorization: Token your-sekrit-key' \
       https://appeals.cf.ds.va.gov/api/v2/hearings/2019-06-07
```

On success returns `200` HTTP code and a body like:

```json
{
   "hearings" : [
      {
         "address" : "15 New Sudbury Street JFK Federal Building",
         "appeal" : "182fd411-c770-44c8-8491-0de36ac6f92c",
         "city"   : "Boston",
         "facility_id" : "vba_301",
         "first_name" : "John",
         "last_name" : "Veteran",
         "participant_id" : "12345",
         "hearing_location" : "Boston",
         "room" : "123",
         "scheduled_for" : "2019-07-24T13:30:00.000-04:00",
         "ssn" : "666456999",
         "state" : "MA",
         "timezone" : "America/New_York",
         "zip_code" : "02203"
      },
      {
         "address" : "123 Main St.",
         "appeal" : "d69d7c3f-fd68-45aa-9bb9-556622fd557b",
         "city"   : "Providence",
         "facility_id" : "vba_999",
         "first_name" : "Jane",
         "last_name" : "Veteran",
         "participant_id" : "23456",
         "hearing_location" : "Providence",
         "room" : "456",
         "scheduled_for" : "2019-07-24T13:30:00.000-04:00",
         "ssn" : "666456000",
         "state" : "RI",
         "timezone" : "America/New_York",
         "zip_code" : "12345"
      }
   ]
}
```
# _v3_
The version 3 namespace is reserved for the [Decision Review API](#decision-review-api)

### Decision Review API

As a complement to the claims assistants' intake UI, _Caseflow Intake_, the Decision Review API provides a way for users _outside of the VA_ (veterans, VSOs, etc) to create, edit, view, delete, and check the status of decision reviews.

#### Documentation

The authorative documentation for the Decision Review API's endpoints is maintained in a single file
```
app/controllers/api/docs/v3/decision_reviews.yaml
```
which is served via the [v3 documentation endpoint](#docs).

The easiest way of viewing the documentation is via https://dev-developer.va.gov/explore/appeals/docs/decision_reviews which pulls `decision_review.yaml` from Caseflow (using the documentation endpoint) and renders it in an easy-to-read format with css, collapsible sections, etc.

The second easiest would be pasting the text of `decision_review.yaml` into: http://editor.swagger.io/

`decision_review.yaml` uses the [OpenAPI specification](https://swagger.io/specification/) (Swagger).

#### Differences Between Using the API Through Lighthouse vs. Using it Directly

Firstly, what is meant by "Through Lighthouse" and "Using it Directly":

Caseflow is only accessible inside VA networks, which non-VA employees / contractors have no access to. The developer portal (Lighthouse) provides access to the Decision Review API (and other APIs) via API key which an individual has to [apply for](https://developer.va.gov/apply). This API key is unrelated to a [Caseflow API key](#api-keys). There are plans to provide access to the endpoints via OAuth as well. For MVP (serving va.gov), only API key access will be available.

The _path_ of a route **isn't** translated at the Lighthouse layer (for the most part). Example:

```
                                       ⬇ identical starting here
https://dev-api.va.gov/services/appeals/v3/decision_review/$1
              http://localhost:3000/api/v3/decision_review/$1
```
The routes as defined in `config/routes.rb` should be mostly identical to those defined in the [developer portal](https://dev-developer.va.gov/explore/appeals/docs/decision_reviews).

##### Example Curl Through Lighthouse
```
curl -v POST https://dev-api.va.gov/services/appeals/v3/decision_review/$1 -H "apikey: LIGHTHOUSE-ISSUED-API-KEY" -d @test.json -i -H "Content-Type: application/json"```
```
##### Example Curl to Caseflow Directly
```
curl -v POST http://localhost:3000/api/v3/decision_review/$1 -H "Authorization: Token token=CASEFLOW-API-KEY" -d @test.json -i -H "Content-Type: application/json"
```


**Note:** The curl examples above expect completely different API keys. Watch out for this.

#### Implementation Notes

The Decision Review API depends heavily on the existing controllers/models/classes that support Caseflow Intake, but diverges where necessary to support the different audience of the API. The Decision Review API is actively being developed with an MVP of supporting a va.gov front end for veterans to submit their own decision reviews.

##### JSON:API

In keeping with other APIs associated with the Lighthouse project, the Decision Review API returns JSON conforming to the [JSON:API ](https://jsonapi.org/format/) specification (v1.0).

##### Renaming of Fields

Some model attributes are renamed to shield a consumer of the Decision Review API from unnecessary complexity or verbosity. Examples:

  * `vacols_id` to `legacyAppealId`
  * `vacols_sequence_id` to `legacyAppealIssueId`
  * `rating_issue_reference_id` to `ratingIssueId`


#### The Lighthouse Project

https://developer.va.gov/

>OIT’s Lighthouse program is VA’s open API platform that creates a single, secure front door to VA’s data for both VA and our partners.

(quote from [press release](https://www.blogs.va.gov/VAntage/58726/lighthouse-veteran-centered-api-program-va/))


# _other APIs / endpoints_

## docs

The Decision Review API is documented in:
```
app/controllers/api/docs/v3/decision_reviews.yaml
```
using the [OpenAPI specification](https://swagger.io/specification/) (Swagger).

This file is served via:
```
GET /api/docs/v3/decision_reviews
```
**Note:** the route isn't:
```
GET /api/v3/docs/decision_reviews
```
(or any other variation). This directory structure is a precendent set by other APIs within the Lighthouse project.

This endpoint does not require an API key.

## metadata endpoint

The metadata endpoint (`GET api/metadata`) is used by the Lighthouse developer portal to fetch metadata (version, health-check, documentation path) about the Decision Review API.