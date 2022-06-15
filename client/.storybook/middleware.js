const express = require('express');

const expressMiddleWare = router => {
    router.get('/users', (request, response) => {
        let userRole = request.query.role;

        if (userRole === "Judge") {
            response.send({ judges: [{ id: 1, fullName: 'Storybook Judge' }] });
            response.end();
        }

        response.status(404).send(`"${userRole}" role does not have have a sample response yet.`);
    })
};
module.exports = expressMiddleWare;