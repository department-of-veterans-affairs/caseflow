Setup json server

Step 1: Open a terminal

Step 2: Navigate to the caseflow/client

step 3: Run command: npm install json-server

step 4: Run command: npm run webex-server

step 5: If you would like to autogenerate test data, run this command: npm run generate-webex

\*info: You will recieve all available routes within the terminal under 'Resources'

\*info: port must be set on a different port to run due to caseflow running on port 3000

step 5: Open a browser window in chrome and navigate to localhost:3050 [You will get the default page]

\*info: You can use any api endpoint software you want like Postman, but a good lightweight vs code ext. is [Thunder Client]

\*info: reference guides
[https://github.com/typicode/json-server/blob/master/README.md]


Tutorial Resources:
[https://www.youtube.com/watch?v=_1kNqAybxW0&list=PLC3y8-rFHvwhc9YZIdqNL5sWeTCGxF4ya&index=1]

To create a meeting the request body must have all of the keys and hit this endpoint?
[http://localhost:3050/fake.api-usgov.webex.com/v1/meetings]

Get all conferencelinks with this endpoint
[http://localhost:3050/api/v1/conference-links]




