import React from 'react';
import { Route } from 'react-router';
import PageRoute from '../../components/PageRoute';

import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import { RecommendDocketSwitchContainer } from './recommendDocketSwitch/RecommendDocketSwitchContainer';
import { DocketSwitchRulingContainer } from './judgeRuling/DocketSwitchRulingContainer';

const PageRoutes = [
  <PageRoute
    path={`/queue/appeals/:appealId/tasks/:taskId/${
      TASK_ACTIONS.DOCKET_SWITCH_SEND_TO_JUDGE.value
    }`}
    title={`${TASK_ACTIONS.DOCKET_SWITCH_SEND_TO_JUDGE.label} | Caseflow`}
  >
    <RecommendDocketSwitchContainer />
  </PageRoute>,

  <PageRoute
    path={`/queue/appeals/:appealId/tasks/:taskId/${
      TASK_ACTIONS.DOCKET_SWITCH_JUDGE_RULING.value
    }`}
    title={`${TASK_ACTIONS.DOCKET_SWITCH_JUDGE_RULING.label} | Caseflow`}
  >
    <DocketSwitchRulingContainer />
  </PageRoute>,

  // This route handles the remaining checkout flow
  <Route path="/queue/appeals/:appealId/tasks/:taskId/docket_switch/checkout">
    {/* The component here will add additional `Switch` and child routes */}
    <h2>Checkout Container</h2>
  </Route>,
];

const ModalRoutes = [];

export const docketSwitchRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
