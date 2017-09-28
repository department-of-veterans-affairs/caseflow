
In Caseflow, internal Functions/Roles are handled through a file (appeals-deployment/ansible/vars/functions-config.yml) that contains a list of users for each environment and each application. For instance:
certification: {
    demo: [
      {
        function_name: "System Admin",
        grant: '["CF_Q_283", "VHAISASOMEONE"]',
        deny: '["CF_SCOTTY_283"]'
      }
    ]...

For this particular case in certification, demo environment, it would grant CF_Q_283 and VHAISASOMEONE users and it would deny CF_SCOTTY_283 with System Admin function.
To add or deny function to a certain user, you would have to add the user's CSS_ID to this file, make a PR for this code change and merge it. Make sure you use the right environment(s) and that you are preserving the existing list (if that's your intention). The empty list will remove all users who were granted/denied the function. Also, the same CSS_ID cannot be both granted and denied the same function.

Note: For the function/roles, Caseflow currently ignores System Admin function from CSUM/CSEM users.

For manual handling of Functions check out Commons project:
https://github.com/department-of-veterans-affairs/caseflow-commons
