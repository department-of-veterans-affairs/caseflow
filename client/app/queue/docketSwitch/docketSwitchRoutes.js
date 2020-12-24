import React from 'react';
import { Route, Switch } from 'react-router';
import PageRoute from '../../components/PageRoute';

import TASK_ACTIONS from '../../../constants/TASK_ACTIONS';
import { RecommendDocketSwitchContainer } from './recommendDocketSwitch/RecommendDocketSwitchContainer';
import { DocketSwitchRulingContainer } from './judgeRuling/DocketSwitchRulingContainer';
import { DocketSwitchDenialContainer } from './denial/DocketSwitchDenialContainer';
import { DocketSwitchGrantContainer } from './grant/DocketSwitchGrantContainer';

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
    <Switch>
      <PageRoute
        path={`/queue/appeals/:appealId/tasks/:taskId/${
      TASK_ACTIONS.DOCKET_SWITCH_DENIED.value
    }`}
        title={`${TASK_ACTIONS.DOCKET_SWITCH_DENIED.label} | Caseflow`}
      >
        <DocketSwitchDenialContainer />
      </PageRoute>
      <PageRoute
        path={`/queue/appeals/:appealId/tasks/:taskId/${
      TASK_ACTIONS.DOCKET_SWITCH_GRANTED.value
    }`}
        title={`${TASK_ACTIONS.DOCKET_SWITCH_GRANTED.label} | Caseflow`}
      >
        <DocketSwitchGrantContainer />
      </PageRoute>
    </Switch>
  </Route>,
];

const ModalRoutes = [];

export const docketSwitchRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
