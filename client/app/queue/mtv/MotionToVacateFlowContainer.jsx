import React, { useMemo } from 'react';
import { useSelector } from 'react-redux';
import { useParams, useRouteMatch, Switch, Route, generatePath } from 'react-router';
import { appealWithDetailSelector } from '../selectors';
import { MotionToVacateContextProvider } from './MotionToVacateContext';
import { AddDecisionIssuesView } from './AddDecisionIssuesView';
import { ReviewVacatedDecisionIssuesView } from './ReviewVacatedDecisionIssuesView';
import { getSteps, getNextStep, getPrevStep } from './mtvCheckoutSteps';
import { SubmitVacatedDecisionsView } from './SubmitVacatedDecisionsView';

export const MotionToVacateFlowContainer = () => {
  const { path } = useRouteMatch();
  const { appealId, taskId } = useParams();
  const basePath = generatePath(path, { appealId,
    taskId });

  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));

  const steps = useMemo(() => getSteps(appeal), [appeal.type, appeal.vacateType]);

  const initialState = {
    // cloning the individual issues
    decisionIssues: appeal.decisionIssues.map((issue) => ({ ...issue })),
    steps,
    getNextUrl: (current) => (getNextStep(current, steps) ? `${basePath}/${getNextStep(current, steps)}` : null),
    getPrevUrl: (current) => (getPrevStep(current, steps) ? `${basePath}/${getPrevStep(current, steps)}` : null)
  };

  return (
    <React.Fragment>
      <MotionToVacateContextProvider initialState={initialState}>
        {/* MTV Progress Bar (#13319) Here */}

        <Switch>
          <Route path={`${path}/review_vacatures`}>
            <ReviewVacatedDecisionIssuesView appeal={appeal} />
          </Route>

          <Route path={`${path}/add_decisions`}>
            <AddDecisionIssuesView appeal={appeal} />
          </Route>

          <Route path={`${path}/submit`}>
            <SubmitVacatedDecisionsView appeal={appeal} />
          </Route>
        </Switch>
      </MotionToVacateContextProvider>
    </React.Fragment>
  );
};
