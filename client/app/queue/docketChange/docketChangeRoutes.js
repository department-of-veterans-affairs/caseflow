import React from 'react';
import { Route } from 'react-router';
import PageRoute from '../../components/PageRoute';

import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';

const PageRoutes = [
  <PageRoute
    path={`/queue/appeals/:appealId/tasks/:taskId/${
      TASK_ACTIONS.DOCKET_CHANGE_SEND_TO_JUDGE.value
    }`}
    title={`${TASK_ACTIONS.DOCKET_CHANGE_SEND_TO_JUDGE.label} | Caseflow`}
  >
    {/* Replace with actual component */}
    <h2>Send to Judge</h2>
  </PageRoute>,

  <PageRoute
    path={`/queue/appeals/:appealId/tasks/:taskId/${
      TASK_ACTIONS.DOCKET_CHANGE_JUDGE_RULING.value
    }`}
    title={`${TASK_ACTIONS.DOCKET_CHANGE_JUDGE_RULING.label} | Caseflow`}
  >
    {/* Replace with actual component */}
    <h2>Judge Ruling</h2>
  </PageRoute>,

  // This route handles the remaining checkout flow
  <Route path="/queue/appeals/:appealId/tasks/:taskId/docket_change/checkout">
    {/* The component here will add additional `Switch` and child routes */}
    <h2>Checkout Container</h2>
  </Route>,
];

const ModalRoutes = [];

export const docketChangeRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
