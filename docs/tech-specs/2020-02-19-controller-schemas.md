## Context

As a result of investigating non-rating request issues with missing decision dates (#12913), I proposed adding backend validation to protect against future occurrences of this issue. Apart from using ActiveRecord validation, I also raised the possibility of schema validations at the Rails controller level during the 2020/01/16 engineering huddle. @pkarman provided good perspective on the Rails community's preference to rely on ActiveRecord and avoid putting too much logic in controllers. Since schema validation was not something the Caseflow team had discussed before, we decided to move it to the purview of the Backend Working Group, with a draft pull request being the next step.

This PR is a hybrid of a tech spec, which lays out the motivations and general requirements of schema validation, and a sample implementation for a single endpoint (`IntakesController#review`). This draft implementation uses [dry-schema](https://dry-rb.org/gems/dry-schema/1.4/) to demonstrate a proof of concept and explore a few different approaches to integrating dry-schema into the Rails app. However, the choice of validation library is by no means a foregone conclusion, and several alternatives are evaluated.

A couple things to note:
- Broadly speaking, a schema is just a list of named fields, usually with fixed types. Most Rails codebases, Caseflow included, of course already have something called a schema: `db/schema.rb` defines the database schema with an ActiveRecord DSL. For brevity, this document uses "schema" to refer to the parameters of an HTTP request, and makes it obvious when also referring to ActiveRecord and the storage layer.
- Much of this draft is informed by similar work I've done in Python with the [Flask](https://www.palletsprojects.com/p/flask/) / [Marshmallow](https://marshmallow.readthedocs.io/en/stable/) / [APISpec](https://apispec.readthedocs.io/en/latest/) ecosystem to generate [Swagger](https://swagger.io/docs/specification/about/) specs. I've tried my best to avoid leaning on knowledge of Python in this document, except in passing to provide additional context.


## Overview

A web application's endpoints constitute an API in the general sense of a boundary between the frontend and the backend. The protocol is well-defined by the HTTP standard, and in Rails, `config/routes.rb` declares the list of available endpoint URLs. This file also serves as documentation for readers familiar with the routing DSL. However, the parameters of each endpoint are only loosely enforced within the app codebase (sometimes by logic far from the endpoint) and not documented at all.

Although the endpoints used by the Caseflow frontend are not formally published as an API for third-party clients (cf. the Lighthouse API), the following benefits of using schema validation still apply to Caseflow:
- Documentation: Schemas, being declarative in nature, can be automatically converted into structured documentation, which is useful for frontend engineers to consult when understanding endpoints and their parameters. [[0]](#note-0)
- Colocated logic: All schema validation is performed in the same place within the codebase, saving backend engineers from needing to follow the flow of a request through many files. Along the same lines, all error messages related to invalid parameters are raised from the same place.
- Early error detection: If an HTTP call is made with invalid parameters, the request can fail-fast and stop all further application logic from running on flawed input. From a systems engineering and security perspective, this is an important defense layer to prevent breaches or bad data from reaching the database.

One concern brought up during the huddle is that Rails convention keeps controllers thin, and any approach to adding schema validations should be cognizant of this. Relatedly, we would like to avoid using schemas to perform complex validations, which would make schemas heavy and burdensome. Drawing on the OpenAPI/Swagger format for inspiration, a useful rule here is that validations should be restricted to single parameters only, disallowing e.g. "param_b must be present if param_a is true" and limiting validations to caring about the type and format of parameters.

Note that endpoint schemas are a supplement, not at all a replacement, for ActiveRecord validations. Just as schemas are both protection and documentation at the frontend/backend boundary, ActiveRecord validations are both protection and documentation at the Rails/SQL boundary. In addition, there is frequently no one-to-one mapping between an HTTP parameter and a database field.

**(Edit 2020/02/19)** It is therefore important that any new API schema validation stay de-coupled from existing ActiveRecord validations. This document does not propose removing any of the latter, since they will continue to be useful as documentation for the storage layer and particularly for work that runs in a Rails environment (scripts and Rails console sessions). It is possible that a de-coupled approach will result in double-duty validation for parameters that go straight into the DB, but this should be considered a good thing: it ensures that we can change either the API or the DB without validation automatically affecting the other.

<a name="note-0">[0]</a> In the Python ecosystem, Marshmallow's APISpec plugin is commonly used to generate OpenAPI/Swagger specs, which in turn can generate both interactive documentation and code for API clients in a wide variety of languages. This was alluded to in the huddle, though there is likely little value in Caseflow going this far.

## Implementation

### Libraries

Every language generally has at least a couple schema validation libraries, which are largely intended to be used alongside web frameworks (and may or may not be coupled with the related task of serialization and deserialization). A few of the Ruby libraries I know of are:
- [apipie-rails](https://github.com/Apipie/apipie-rails) - strongly encourages inline schemas preceding each controller method; auto-generates documentation
- [dry-rb](https://dry-rb.org/) - a group of gems, most relevantly: [dry-logic](https://dry-rb.org/gems/dry-logic/1.0/), [dry-schema](https://dry-rb.org/gems/dry-schema/1.4/), [dry-types](https://dry-rb.org/gems/dry-types/1.2/), [dry-validation](https://dry-rb.org/gems/dry-validation/1.4/)
- [jsonapi-rb](http://jsonapi-rb.org/) - focused on serializing and deserializing JSON payloads, with validation
- [rails_param](https://github.com/nicolasblanco/rails_param) - lightweight, recommended for few parameters; implemented as method calls at the top of each controller method
- **(Edit 2020/02/19)** [grape](https://github.com/ruby-grape/grape#parameter-validation-and-coercion) - opinionated REST API framework

My choice for this draft is dry-schema, which provides standalone schema objects that can be referenced by controller methods while keeping the controllers thin. It is used heavily by dry-validation, which goes beyond schemas and focuses on the type of app-logic validation that we are intentionally not exploring here.

It's possible that, with some effort, apipie-rails and rails_param can be used without colocating schema declarations beside/inside controller methods. The capability of apipie-rails to autogenerate HTML documentation out of the box is especially appealing. The one library on this list that does not appear viable is jsonapi-rb, which is not interested in non-JSON payloads, unsurprisingly.

**(Edit 2020/02/19)** Grape is a Ruby framework designed for building out RESTful APIs using a fairly opinionated approach and syntax. The library as a whole feels too heavy to be used solely for its schema validator, judging from its opinionated recommendation for Rails integration (e.g. "Place API files into `app/api`... Modify `config/routes` with `mount Example::API => '/'`")

### Integration

Many Python validation libraries, including [flask-apispec](https://flask-apispec.readthedocs.io/en/latest/), are activated by augmenting controller methods with Python [decorators](https://www.python.org/dev/peps/pep-0318/), which read like comments and usually add behavior before/after the method -- very ergonomic for schemas. Since there is no convention for associating dry-schema's standalone objects with a controller method, this draft implementation offers code for three possible approaches, using `IntakesController#review` as the sample:
- Approach 1: Implement `IntakesController#review_schema`. Most flexible.
- Approach 2: Add a constant `SCHEMAS` class to the controller, and call `#review` on that class.
- Approach 3: Call `IntakesSchemas#review`. Most reliant on convention.

Note that while approach 1 requires the most additional code per decorated method, it is also the only one whose logic involves an actual Controller instance. This would be necessary if `routes.rb` sent multiple HTTP verbs to the same method -- although doing so is largely discouraged, apart from same-schema situations like overloading POST/PATCH.

There are, of course, many other approaches that share similarities to these three, as well as the more ActiveRecord-like approach of [declarative code](https://martinfowler.com/bliki/RubyAnnotations.html) which might look like

```
validates :review, using: IntakesSchema::REVIEW_SCHEMA
```

This last approach may be the most stylistically suitable for a Rails codebase, but a first-pass implementation ended up touching more ApplicationController internals than I was comfortable committing to.

**(Edit 2020/02/19)** All approaches described here also require a `before_action` hook to trigger the validation at the beginning of an actual HTTP request. Initially, this was done in `ApplicationController`, automatically enabling validation for all controllers in the codebase. On @pkarman's suggestion, this has been moved to a `ValidationConcern` class, which must be included by any controller to enable validation.

### Documentation

The draft implementation also provides a sample API documentation generator that converts schema objects to plain-text or JSON output, exposed as a new `/route_schemas` route to the controller method `RouteSchemasController#index`. This component was the heaviest lift that resulted from choosing dry-rb, since schema objects represent validation logic as an AST of predicates rather than a list of rules, despite being declared in code as a list of rules. The `DocCompiler` class traverses an AST to convert it back into rules, and is a modified version of dry-rb's own sample AST parser. This code is dense but rarely changes, and can be completely replaced if/when [this dry-schema issue](https://github.com/dry-rb/dry-schema/issues/36) is resolved.

Currently, plain-text output of the documentation generator for `IntakesController#review` looks something like

```
PATCH /intake/:id/review(.:format)
  receipt_date {:required=>true, :type=>"date", :filled=>true}
  docket_type {:required=>true, :type=>"enum", :values=>["direct_review", "evidence_submission", "hearing"]}
  claimant {:required=>true, :type=>"string"}
  veteran_is_not_claimant {:required=>true, :type=>"boolean", :filled=>true}
  payee_code {:required=>true, :type=>"string"}
  legacy_opt_in_approved {:required=>true, :type=>"boolean", :filled=>true}
```

The JSON output reads similarly, and by intention, loosely resembles an OpenAPI/Swagger spec without conforming to the exact format. Both plain-text and JSON renderers are implemented directly within `RouteSchemasController` as an invitation to rethink what form of documentation would be most useful for the team. There are many possibilities, for example: a small frontend app consuming JSON; or, a page on the Caseflow wiki.

One downside of using dry-schema objects is that adding descriptions to schema parameters requires non-trivial engineering, as the AST only stores logic, not metadata. From a documentation perspective, it can be helpful for parameters to have accompanying prose, in case the name and validation rules aren't sufficient. This is especially important for the occasional "param_b must be present if param_a is true" cases, where single-parameter rules cannot capture all aspects of input validity.

**(Edit 2020/02/19)** @jcq raised the question of whether it's worth using OpenAPI/Swagger as the target format of the JSON output. There are a few common benefits provided by the Swagger tooling ecosystem:
- [Swagger UI](https://swagger.io/tools/swagger-ui/), which generates API documentation in the form of an interactive web app. A [live demo](https://petstore.swagger.io/) is available on the Swagger site.
- [Swagger Codegen](https://swagger.io/tools/swagger-codegen/), which generates stub server and client code (in many programming languages), often used as the low-level core of SDKs. Likely not relevant to Caseflow's needs in the foreseeable future.
- [SwaggerHub](https://swagger.io/tools/swaggerhub/), hosted versions of this tooling, with some additional bells and whistles like a fancy web-based text editor for Swagger JSON. Almost certainly not relevant to Caseflow.

It would be fairly straightforward to massage the input schemas into Swagger-compatible format, but the full benefit of Swagger UI is realized when the spec also contains output schemas, i.e. fields and types of the JSON objects returned by each endpoint. While we could ask what's involved in integrating our `fast_json` Serializers into Swagger (probably a significant lift), speculation on converting our React endpoints to data endpoints in favor of a pure-API frontend is far outside the scope of this document.


## Open Questions

In order of increasing specificity with respect to this draft implementation:
- What other schema validation libraries for Ruby should we consider?
- Is there value in generating separate endpoint documentation, compared to just referencing the schema declarations in the backend code?
  - **(Edit 2020/02/19)** Is it worth outputting JSON that conforms to OpenAPI/Swagger? If so, how much of the Swagger spec should be supported?
- Are the benefits of dry-rb worth the effort of writing/maintaining code for both 
  - parsing dry-logic's AST and
  - generating documentation?
- What other approaches for associating a schema with a controller method should we consider?
- Is `ApplicationController#before_action` the best way to trigger validation at the start of a request?
  - **(Edit 2020/02/19)** Does `include ValidationConcern` feel like a better alternative to calling `before_action` in ApplicationController?
- How difficult is it to extend the validation library to support prose descriptions on each parameter?


## Rollout

As there are no plans to formally publish user-facing schema documentation for the Caseflow app, rollout can be done on an endpoint-by-endpoint basis as backend engineering gradually adds validation to the codebase's many controller methods. In order to motivate adding validation, something modeled after the frontend warnings for React components missing PropTypes could be considered.

Because schema validation always makes an endpoint more restrictive and less accepting of arbitrary input, tests that exercise happy-path flows across one or more API calls are generally sufficient to provide the confidence that new validation hasn't introduced any regressions. Fortunately, Caseflow's feature tests are already fairly comprehensive at testing happy paths. One area of caution is when a parameter's validation rule presents edge cases, for example:
- a parameter that normally receives a value, but occasionally may be `null`,
- a boolean parameter that sometimes receives `null` in place of `false`, or
- an integer parameter that is normally non-negative, but occasionally accepts `-1` as a sentinel value.

It is therefore important for the engineer to have a good understanding of the range of accepted input when adding validation for a method, and to keep an eye out for UI flows that result in API calls with edge-case values. However, the general problem of parameters with edge cases, and the related issue of how feature tests can be improved to exercise edge case flows, are outside the scope of this document.

