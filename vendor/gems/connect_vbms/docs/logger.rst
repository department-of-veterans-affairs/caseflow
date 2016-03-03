Audit Logging
-------------

The constructors for the ``VBMS::Client`` class accept an optional argument for a logger instance. This allows you to audit the requests being sent to the VBMS backend from the client through several defined callbacks from within the client code. It should **not** be sent a standard logger instance from Ruby or Rails. Instead, you must define a Logger class that implements the following interface

.. code-block:: ruby

  class SampleLogger
    def log(event, data)
      case event
      when :unencrypted_xml
        # do something
      when :request
        # something else
      when :decrypted_message
        # final callback
      end
    end
  end

The ``log`` method must accept two parameters that will be provided with the following values

* ``event`` (``Symbol``): the type of the event
* ``data`` (``Hash``): the specific data associated with the event

Note that the contents of the ``data`` hash will vary depending on the message. Currently, the logger will be called with these types of messages

**unencrypted_xml**

This logging callback is called at the beginning of building the request to VBMS, before the XML message is placed within a SOAP envelope and encrypted and signed.

* ``:unencrypted_body`` (``String``) the XML of the request

**request**

This logging callback is invoked immediately after the request is sent to the VBMS API. It includes the following fields in its data hash

* ``:response_code`` (``Integer``) - the response code returned from the VBMS server
* ``:request_body`` (``String``) - the request sent to the VBMS server
* ``:response_body`` (``String``) - the raw contents of the response received from VBMS
* ``:request`` (``VBMS::Requests``) - the ``VBMS::Requests`` object for the request
* ``:duration`` (``Float``) - the length of time, in seconds, that the request took

**decrypted_message**

This logging callback is called immediately after the SOAP response from VBMS is decrypted. It provides the following parameters:

* ``:decrypted_data`` (``String``) - the decrypted XML received from VBMS
* ``:request`` (``VBMS::Requests``) - the ``VBMS::Requests`` object
