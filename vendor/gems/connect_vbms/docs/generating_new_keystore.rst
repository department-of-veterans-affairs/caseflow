
================================
Generating new keystore fixtures
================================

Use this script to generate new keystore fixtures for running the test suite. This keystore includes a generated certificate set to expire 365 days after creation.


1. Enter the project's ``/script`` directory with ``cd script`` from the project root.

2. Execute the script to generate the keystore with ``./generate_keystore.sh``.

3. **When prompted to enter a keystore password, always use** ``importkey``.

4. **When prompted to overwrite existing keys and keystores, enter** ``y``.

5. When prompted to trust the certificate, enter ``yes``.

6. You will be prompted for the "export password" again, enter ``importkey``.

7. When prompted for the "source keystore password" again, enter ``importkey``.

8. When prompted to overwrite the existing test_keystore_vbms_server_key.p12, enter ``y``.

9. When prompted to overwrite the existing test_keystore.jks, enter ``y``.

10. Finally, the script will show the generated keystore and will prompt you for the password. Enter ``importkey``.
