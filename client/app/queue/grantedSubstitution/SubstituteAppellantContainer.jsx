import React, { useMemo } from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ProgressBar from 'app/components/ProgressBar';
import { useSelector } from 'react-redux';
import { Redirect, Route, Switch, useRouteMatch } from 'react-router';
import { GrantedSubstitutionBasicsView } from './GrantedSubstitutionBasicsView';

const sections = [
  'Select substitute appellant',
  'Select POA',
  'Create task',
  'Review',
];

export const SubstituteAppellantContainer = () => {
  const { path, url } = useRouteMatch();

  // These can be used to access the appeal or task via other selectors
  // const { appealId, taskId } = useParams();

  const step = useSelector((state) => state.substituteAppellant.step);

  // Keep our progress bar updated based on current step
  const pbSections = useMemo(
    () => sections.map((title, idx) => ({ title, current: idx === step })),
    [step]
  );

  return (
    <AppSegment>
      <ProgressBar sections={pbSections} />
      <Switch>
        <Redirect exact from={[url, `${url}/`]} to={`${url}/basics`} />
        <Route path={`${path}/basics`} title="Substitute Appellant | Caseflow">
          <GrantedSubstitutionBasicsView />
        </Route>
      </Switch>
    </AppSegment>
  );
};
