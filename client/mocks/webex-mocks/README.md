Setup json server

Step 1: Open a terminal

Step 2: Navigate to the caseflow/client

step 3: Run command: [npm install json-server] or [yarn add json-server]

If the [npm install json-server] or [yarn add json-server]  returns an error that resembles:

error standard@17.1.0: The engine "node" is incompatible with this module. Expected version "^12.22.0 || ^14.17.0 || >=16.0.0". Got "15.1.0"

extra steps may need to be taken.

for brevity These instructions will follow the happy path.  While in the client directory in terminal:
[nodenv install 14.21.2]
[nodenv local 14.21.2]

If for any reason you want to go back to the original nodenv that was used prior to this change you can run, [nodenv local 12.13.0]

If it all succeeds you can attempt the [npm install json-server] or [yarn add json-server]  once again.

This time with no issue.
given that the install goes as expected you can continue following the rest of the directions.

If there are still issues in getting this to operate as expected, See your tech lead for asssisstance.

step 4: Make sure casfelow application is running

step 5: Autogenerate test data, run this command: npm run generate-webex(This will also create the json file)

step 6: Run command: npm run webex-server

\*info: You will recieve all available routes within the terminal under 'Resources'

\*info: port must be set on a different port to run due to caseflow running on port 3000

step 7: Open a browser window in chrome and navigate to localhost:3050 [You will get the default page]

\*info: You can use any api endpoint software you want like Postman, but a good lightweight vs code ext. is [Thunder Client]

\*info: reference guides
[https://github.com/typicode/json-server/blob/master/README.md]

Tutorial Resources:
[https://www.youtube.com/watch?v=_1kNqAybxW0&list=PLC3y8-rFHvwhc9YZIdqNL5sWeTCGxF4ya&index=1]

To create a meeting the request body must have all of the keys and hit this endpoint?
[http://localhost:3050/fake.api-usgov.webex.com/v1/meetings]

Get all conferencelinks with this endpoint
[http://localhost:3050/api/v1/conference-links]

Javascript API call Fetch/Axios examples
[https://jsonplaceholder.typicode.com/]




