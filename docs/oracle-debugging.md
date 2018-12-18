# Oracle Common Issues

## Issues connecting to db

### client host name is not set

If you get the following issue:

```
OCIError:
  ORA-24454: client host name is not set
```

The fix is to edit your `/etc/hosts` file and alias `127.0.0.1` to the hostname of your computer. You'll need to keep updating this if your hostname changes.

Then restart your docker containers via `docker-compose restart`, otherwise the hostname mappings aren't picked up and you'll hit this error:

```
OCIError:
  ORA-12514: TNS:listener does not currently know of service requested in connect descriptor
```
