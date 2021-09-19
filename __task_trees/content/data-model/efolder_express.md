---
title: eFolder Express
weight: 5
---

# eFolder Express
* [eFolder Express tables diagram](https://dbdiagram.io/d/5ed6741c39d18f555300202a)

Caseflow eFolder Express (EE) serves the specific role of allowing users to bulk download all of a Veteran's files at once. It is the only Caseflow product that has a separate [code repository](https://github.com/department-of-veterans-affairs/caseflow-efolder) and runs on separate servers.

## Records
When mentioning a Veteran's files in EE, those can vary between PDFs, TIFFs, and IMGs. The Records table exists to store references to these files


## Manifests
As mentioned above, the purpose of EE is to allow users to download all of a Veteran's files at once. The reasoning for this is to reduce the need for the user to select and download files individually. A `Manifest` represents the collection of all of a Veteran's files and consists of a `ManifestSource` for each file, pointing to its source.

## ManifestSources
The sources for files made available for download in EE are [VBMS](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/VA-API-services#vbms) and [Virtual VA (VVA)](https://github.com/department-of-veterans-affairs/appeals-deployment/wiki/VA-API-services#vva). A `ManifestSource` groups a set of `Records` to allow all of a Veteran's files to be downloaded at the same time.
* `name`: Either "VBMS" or "VVA"
* `status`: Stores whether a `Record` was successfully added to a `Manifest`

## FileDownloads
When a user searches for the Veteran they are looking for in EE, they are presented with a view of all files available for download. The FileDownloads table stores each time a user downloads all of a Veteran's files.

## Relationships
In the diagram below you can see that every `FileDownload` will store a `manifest_id`, as well as every `ManifestSource`. This makes sense given the fact that a `Manifest` is a collection of `ManifestSources`, with each `ManifestSource` containing a `Record`. The files indirectly referenced by a `Manifest` can be downloaded as many times as needed.

<img src="https://user-images.githubusercontent.com/63597932/101203241-64137f80-3638-11eb-98b7-ebdc95a39533.png" width=800>

