Contributing
============

We aspire to create a welcoming environment for collaboration on this
project.

Public domain
-------------

This project is in the public domain within the United States, and
copyright and related rights in the work worldwide are waived through
the `CC0 1.0 Universal public domain dedication`_.

All contributions to this project will be released under the CC0
dedication. By submitting a pull request, you are agreeing to comply
with this waiver of copyright interest.

Communication
=============

You should be using the master branch for most stable release, please
review `release notes`_ regularly. We’re generally using `semantic
versioning`_, but we’re pre-1.0, so the API can change at any time. We
use the minor version for when there are not significant API changes.

Development Process
===================

This project follows a similar development process to `git flow`_. We
use feature branches for all development, with frequent rebases to keep
our feature branches in sync. All pull requests are community reviewed
and must pass our continuous integration spec run and code style
enforcer in `Travis CI`_.

We have a pre-configured :doc:`Vagrant environment <developing_with_vagrant>` which generates a fresh
Ubuntu development environment with all necessary dependencies.

Example:

1. Pull latest code from master branch.

   ::

       git checkout master
       git pull

2. Create a feature branch for your work.

   ::

       git checkout -b feature/do_something_awesome

3. Commit your work and associate with an Issue.

   ::

       git add <files>
       git commit -m"[Issue #<number>] Does something awesome"

4. Push your work up and create a Pull Request for review.

   ::

       git push origin feature/do_something_awesome

Testing Your Work
=================

There are a number of tests and fixture files for this gem written in `rspec`_. When contributing new code, 
please modify or write new tests to verify your code is functioning correctly. In addition, we expect all
tests to comply with the `RuboCop`_ style guide conventions. To run tests and verify your code complies with
our style rules, run the following rake tasks

    ::

        rake default

And make sure it passes before submitting a pull request. Otherwise, your code will almost certainly fail within
Travis CI.

Tests normally mock all web requests so tests can be run without needing any credentials for VBMS systems. To run the integration tests against a VBMS server, you must specify all the necessary ``VBMS_CONNECT`` environment variables. You can then execute tests with 

    ::

        CONNECT_VBMS_RUN_EXTERNAL_TESTS=1 rake default

and it will connect directly to the VBMS for all tests of remote communication. This can be useful for verifying that our mocks are still accurate samples of real VBMS responses.

The encryption and decryption tests use a special test keystore file located in the ``spec/fixtures`` directory whose keys are only valid for a year or so. If your encryption tests suddenly start failing, see :doc:`the instructions for generating a new test keystore<generating_new_keystore>`.

.. _CC0 1.0 Universal public domain dedication: https://creativecommons.org/publicdomain/zero/1.0/
.. _release notes: https://github.com/department-of-veterans-affairs/connect_vbms/releases
.. _semantic versioning: http://semver.org/
.. _git flow: http://nvie.com/posts/a-successful-git-branching-model/
.. _Travis CI: https://travis-ci.org/department-of-veterans-affairs/connect_vbms
.. _rspec: http://rspec.info/
.. _RuboCop: https://github.com/bbatsov/rubocop
