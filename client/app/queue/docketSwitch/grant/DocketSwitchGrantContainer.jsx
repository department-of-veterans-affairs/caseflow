import React, { useMemo } from 'react';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ProgressBar from 'app/components/ProgressBar';
import { useSelector } from 'react-redux';
import { Redirect, Route, Switch, useRouteMatch } from 'react-router';
import { DocketSwitchReviewRequestContainer } from './DocketSwitchReviewRequestContainer';
import { DocketSwitchEditTasksContainer } from './DocketSwitchEditTasksContainer';
import { DocketSwitchReviewConfirmContainer } from './DocketSwitchReviewConfirmContainer';

const sections = ['Review Request', 'Add/Remove Tasks', 'Review & Confirm'];

export const DocketSwitchGrantContainer = () => {
  const { path, url } = useRouteMatch();

  // These can be used to access the appeal or task via other selectors
  // const { appealId, taskId } = useParams();

  const step = useSelector((state) => state.docketSwitch.step);

  // Keep our progress bar updated based on current step
  const pbSections = useMemo(
    () => sections.map((title, idx) => ({ title, current: idx === step })),
    [step]
  );

  return (
    <AppSegment>
      <ProgressBar sections={pbSections} />
      <Switch>
        {/* Default to first step */}
        <Route exact path={url}>
          <Redirect to={`${url}/review_request`} />
        </Route>

        <Route path={`${path}/review_request`}>
          <DocketSwitchReviewRequestContainer />
        </Route>
        <Route path={`${path}/tasks`}>
          <DocketSwitchEditTasksContainer />
        </Route>
        <Route path={`${path}/confirm`}>
          <DocketSwitchReviewConfirmContainer />
        </Route>
      </Switch>
    </AppSegment>
  );
};
