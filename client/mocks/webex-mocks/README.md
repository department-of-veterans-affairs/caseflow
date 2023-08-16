Setup json server

Step 1: Open a terminal

Step 2: Navigate to the caseflow application

step 3: Run command: npm install json-server

step 4: Run command: npx json-server --watch client/mocks/webex-mocks/webex-mock.json --port 3001

*info: You will recieve all available routes within the terminal under 'Resources'

*info: port must be set on a different port to run due to caseflow running on port 3000

step 5: Open a browser window in chrome and navigate to localhost:3001 [You will get an empty object]

*info: reference guides
[https://jsonplaceholder.typicode.com/guide/]
[https://blog.logrocket.com/how-to-bootstrap-your-project-with-json-server/]

step 6: Append the key to the path you are wanting to query [localhost:30001/conference-links]

*info: this will give you the list of objects with the corresponding key

step 7: Append the id to GET the specific id [localhost:30001/conference-links/1]
