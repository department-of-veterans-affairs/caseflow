---
title: Caseflow Reader
weight: 4
---
# Caseflow Reader
* [Caseflow Reader](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Reader) and [Reader Backend](https://github.com/department-of-veterans-affairs/caseflow/wiki/Reader-Backend)
* [Reader tables diagram](https://dbdiagram.io/d/5ed6793d39d18f5553002077)

## Documents
[Caseflow Reader](https://github.com/department-of-veterans-affairs/caseflow/wiki/Caseflow-Reader) allows users to access all of the documents related to the Veteran for an appeal. Users first interact with a *document list* page which presents a list of the documents.  Upon selection of a particular document, they are redirected to the *document view* page where they can view and interact with the document. Documents are populated by [eFolder](https://github.com/department-of-veterans-affairs/caseflow-efolder#caseflow---efolder-express), which retrieves them from two upstream dependencies: VBMS & VVA -- see [Reader Backend](https://github.com/department-of-veterans-affairs/caseflow/wiki/Reader-Backend) for details.

## Annotations
On the document view page, users have the ability to add comments to documents via the "Add a comment" button.  A comment is stored in the `annotations` table.  Once a comment is created, it can be edited, shared via a link or deleted. In addition, comments can be seen on the document list page under the "Comment" column for the related document and also by selecting the "Comments" button which shows all comments.

## Tags
Tags can be added by the user to further label and categorize documents based on issues that they identify.  On the document view page, users may create a tag within the sidebar under the "Issue tags" dropdown section. Once a tag is created, it is saved (in the `tags` table) so that it is available for use on other documents.  Tags can also be deleted by the user.

## DocumentViews
Caseflow keeps track of when a user has viewed a document so the user is aware of which ones they have already opened.  To do this, documents in the document list are initially shown in bold text, however once a user has viewed a document, the text will no longer be bold.

## Relationships
When a tag is created for a document, the user can apply it on other documents that may be relevant.  The `document_tags` table keeps track of which tags apply to which documents.  The `id` of the `tags` table corresponds to the `tag_id`, and the `id` of the documents table corresponds to the `documents_id`.

To track which document a comment/annotation is created for, the `id` from the `documents` table corresponds with the `document_id` on the `annotations` table.

To track when a document has been viewed by a user we have the `document_views` table, the `id` from the `documents` table corresponds with the `document_id` in the `document_views` table, and the `user_id` refers to the `id` in the `users` table.

<img src="https://user-images.githubusercontent.com/55255674/97455894-54509f00-1906-11eb-8104-b409bc4d777a.png" height="600">