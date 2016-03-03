API Requests
============

This is a complete list of the requests that Connect VBMS supports.

``ListDocuments``
-----------------

.. code-block:: ruby

    VBMS::Requests::ListDocuments.new('<file number>')

``ListDocuments`` finds a list of all of the documents in an eFolder for a given
file.

Result
~~~~~~

An ``Array`` of ``VBMS::Responses::Document`` objects.

``FetchDocumentById``
---------------------

.. code-block:: ruby

    VBMS::Requests::FetchDocumentById.new('<document id>')

``FetchDocumentById`` gets the contents and details about a document, by its
identifier.

Result
~~~~~~

A ``VBMS::Responses::DocumentWithContent``.

``GetDocumentTypes``
--------------------

.. code-block:: ruby

    VBMS::Requests::GetDocumentTypes.new()

``GetDocumentTypes`` gets an ``Array`` of all the document types that VBMS
supports.

Result
~~~~~~

An ``Array`` of ``VBMS::Responses::DocumentType``.

``UploadDocumentWithAssociations``
----------------------------------

.. code-block:: ruby

    VBMS::Requests::UploadDocumentWithAssociations.new(
        '<file number>', <received at>, '<first name>', '<middle name>',
        '<last name>', '<exam name>', '<path to pdf>', '<doc type id>',
        '<source>', <new mail>
    )

``UploadDocumentWithAssociations`` creates a new file in the Veteran's eFolder.

Responses
=========

``VBMS::Responses::Document``
-----------------------------

Attributes
~~~~~~~~~~

* ``document_id`` (``String``): a  unique identifier for the document.
* ``filename`` (``String``): the original filename of this document.
* ``doc_type`` (``String``): the id for this document type.
* ``source`` (``String``): where this document came from.
* ``mime_type`` (``String``): the MIME type of the document.
* ``received_at`` (``Date`` or ``nil``): when the VA received this document.

``VBMS::Responses::DocumentWithContent``
----------------------------------------

Attributes
~~~~~~~~~~

* ``document`` (``VBMS::Responses::Document``)
* ``content`` (``String``): the contents of the file

``VBMS::Responses::DocumentType``
---------------------------------

Attributes
~~~~~~~~~~

* ``type_id`` (``String``)
* ``description`` (``String``): a human readable description of the document
  type.
