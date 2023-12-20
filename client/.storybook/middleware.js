/*
 * You can define express.js routes in this file for components you have mounted within
 * Storybook to interact with. Any changes to the routes within this file will only take effect
 * after restarting the Storybook server.
 */

const express = require('express');
const utils = require('./utils');

const expressMiddleWare = router => {
    router.get('/users', (request, response) => {
        let userRole = request.query.role;

        if (userRole === "Judge") {
            response.send({ judges: [{ id: 1, fullName: 'Storybook Judge' }] });
            response.end();
        }

        response.status(404).send(`"${userRole}" role does not have have a sample response yet.`);
    });

    router.get('/appeals/:appealId/power_of_attorney', (request, response) => {

        response.send(
            {
                representative_type: 'Attorney',
                representative_name: 'Clarence Darrow',
                representative_address: {
                    address_line_1: '9999 MISSION ST',
                    address_line_2: 'UBER',
                    address_line_3: 'APT 2',
                    city: 'SAN FRANCISCO',
                    zip: '94103',
                    country: 'USA',
                    state: 'CA'
                },
                representative_email_address: 'tom.brady@caseflow.gov',
                poa_last_synced_at: '2022-10-03T09: 10: 51.266-04: 00'
            }
        );
    });

    // Example url: /decision_reviews/vha?tab=in_progress&page=1
    router.get('/decision_reviews/vha', (request, response) => {
        // const pageNumber = request.query.page;
        response.json({
            tasks: { data: utils.TASKS_ARRAY },
            tasks_per_page: 15,
            task_page_count: 3,
            total_task_count: 44
        });
    });
};
module.exports = expressMiddleWare;
