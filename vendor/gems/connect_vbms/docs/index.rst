
***********************
Welcome to Connect VBMS
***********************

Connect VBMS is an SDK for integrating with VBMS from Ruby.

Getting Started
---------------

To get started, you'll first need to get credentials from the VBMS team.
You'll also need to make sure you have ``javac`` installed (version 1.7 or higher), and run
``rake build`` in the root of the Connect VBMS repo to build a gem in the ``pkg`` dir.

To connect to VBMS, you must be supplied credentials by the administrators. These credentials take the form of several files used for encrypting and authenticating messages between your client and the VBMS endpoint. These credentials will vary depending on which VBMS endpoint you are connecting to. This gem is designed to work only with ``v4`` of the ``eDocumentService`` VBMS API, so you must verify the URL of your endpoint is correct for that service.

.. code-block:: ruby

    require 'vbms'
    client = VBMS::Client.new(
        '<endpoint URL for the environment you want to access>',
        '<path to key store>',
        '<path to SAML XML token>',
        '<path to key, or nil>',
        '<password for key store>',
        '<path to CA certificate, or nil>',
        '<path to client certificate, or nil>',
    )

Alternatively, you can set the values for these fields as environment variables. This approach is preferred since it avoids checking in any credentials to a repository and is one of the requirements for a proper `12-factor application`_ deployment. The environment variables that you must define are:

.. _12-factor application: http://12factor.net/

.. code-block:: bash

    CONNECT_VBMS_URL = '<endpoint URL for the environment you want to access>'
    CONNECT_VBMS_ENV_DIR = '<path to directory where VBMS environments are found>'
    CONNECT_VBMS_KEYFILE = '<relative path of the key store>'
    CONNECT_VBMS_SAML = '<relative path of the SAML token>'
    CONNECT_VBMS_KEYPASS = '<password for key store>'
    CONNECT_VBMS_CACERT = '<path to CA certificate, or nil>'
    CONNECT_VBMS_CERT = '<path to client certificate, or nil>''

Note that the ``CONNECT_VBMS_ENV_DIR`` directory is the place where you put credentials for various environments. So, if you were to connect to the VBMS test environment, the keystore and SAML token must be placed in ``${CONNECT_VBMS_ENV_DIR}/test``. To create a Client object using environment variables in your Ruby code, use the ``Client#from_env_vars`` method:

.. code-block:: ruby

    require 'vbms'
    client = VBMS::Client.from_env_vars(nil, 'test')

The first argument allows you to pass in an optional Logger that will receive events and their data payloads, should you wish to audit that. The second argument is the environment to use the credentials for and defaults to ``test``. To ensure that these environment variables are properly loaded when you are developing your application, we recommend that you should use an automatic environment loader like Ruby's `dotenv`_ or Python's `autoenv`_.

.. _dotenv: https://github.com/bkeepers/dotenv
.. _autoenv: https://github.com/kennethreitz/autoenv

Now you can issue a request, to list the contents of an eFolder:

.. code-block:: ruby

    request = VBMS::Requests::ListDocuments.new("<file number>")

    result = client.send_request(request)

Connect VBMS works by creating request objects, which are pure-data objects to
represent the set of parameters an API call takes. These request objects are
then passed to the client for execution.


Requests Documentation
----------------------

For ``ListDocuments``, the result is a list of ``VBMS::Responses::Document`` objects. For
full details on ``ListDocuments`` and all the other API requests, consult :doc:`requests`

Audit Logging
-------------

The ``VBMS::Client`` constructors accept an optional Logger argument. This is not the Ruby Logger but a class you define
to respond to specific messages from the VBMS Client. For more details, see :doc:`logger`


Contributing
------------

Contributing Guide
==================

View :doc:`Contribution Guidelines <contributing>` for information on contributing to this gem. 

Developing with Vagrant
=======================

View :doc:`developing_with_vagrant` for information on using our prebuilt Vagrant VM for development.

Java Versions
=============

To build with a specific version of Java, see :doc:`crosscompile_java`.
