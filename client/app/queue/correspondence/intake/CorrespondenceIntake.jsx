import React, { useMemo } from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ProgressBar from '../../../components/ProgressBar';
import { useSelector } from 'react-redux';
// import { Redirect, Route, Switch, useRouteMatch } from 'react-router';

const sections = [
  'Add Related Correspondence',
  'Review Tasks & Appeals',
  'Confirm',
];

export const CorrespondenceIntake = () => {
  // const { path, url } = useRouteMatch();

  const step = useSelector((state) => state.cavcRemand.step);

  // Keep progress bar updated based on current step
  const pbSections = useMemo(
    () =>
      sections.map((title, idx) => ({
        title: `${idx + 1}. ${title}`,
        current: idx === step,
      })),
    [step]
  );

  return (
    <AppSegment>
      <ProgressBar sections={pbSections} />
      {/* <Switch>
        <Redirect exact from={[url, `${url}/`]} to={`${url}/basics`} />
        <Route path={`${path}/basics`} title = "Correspondence Intake | Caseflow">
          TBD Container for page 1
        </Route>

        <Route path={`${path}/tasks`} title = "Correspondence Intake | Caseflow">
          TBD Container for page 2
        </Route>

        <Route path={`${path}/review`} title = "Correspondence Intake | Caseflow">
          TBD Container for page 3
        </Route>

      </Switch> */}
    </AppSegment>

  );
};
