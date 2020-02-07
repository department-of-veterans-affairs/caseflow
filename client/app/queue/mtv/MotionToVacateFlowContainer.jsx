import React, { useMemo } from 'react';
import { useSelector } from 'react-redux';
import { useParams, useRouteMatch, Switch, Route, generatePath } from 'react-router';
import { appealWithDetailSelector } from '../selectors';
import { MotionToVacateContextProvider } from './MotionToVacateContext';
import { ReviewVacatedDecisionIssuesView } from './ReviewVacatedDecisionIssuesView';

export const views = {
  review_vacatures: { title: 'Review vacated decision issues' },
  add_decisions: { title: 'Add decisions' },
  submit: { title: 'Submit draft decision for review' }
};

// This is cumbersome... perhaps it would be better modeled as finite state machine..?
export const getSteps = ({ type, vacateType }) => {
  switch (vacateType?.toLowerCase()) {
  case 'straight_vacate':
  case 'vacate_and_de_novo':
    return ['review_vacatures', 'submit'];
  case 'vacate_and_readjudicate':
    return ['review_vacatures', 'add_decisions', 'submit'];
  default:
    return type?.toLowerCase() === 'de_novo' ? ['add_decisions', 'submit'] : [];
  }
};

const getNextStep = (current, steps) => {
  const idx = steps.indexOf(current);

  return idx < steps.length - 1 ? steps[idx + 1] : null;
};

const getPrevStep = (current, steps) => {
  const idx = steps.indexOf(current);

  return idx > 0 ? steps(idx - 1) : null;
};

export const MotionToVacateFlowContainer = () => {
  const { path } = useRouteMatch();
  const { appealId, taskId } = useParams();
  const basePath = generatePath(path, { appealId,
    taskId });

  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));

  // const steps = useMemo(() => getSteps(appeal, [appeal.type, appeal.vacateType]));

  // TODO -- Replace with real line ^^ when params exist
  const steps = useMemo(() => getSteps({ type: 'vacate',
    vacateType: 'straight_vacate' }));

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
            {/* Insert component from #13007 here */}
            <ReviewVacatedDecisionIssuesView appeal={appeal} />
          </Route>
          <Route path={`${path}/add_decisions`}>
            {/* Insert component from #13071 here */}
            {/* <AddDecisionsView appeal={appeal} /> */}
            <h1>add_decisions</h1>
          </Route>
          <Route path={`${path}/submit`}>
            {/* Insert component from #13071 here */}
            {/* <AddDecisionsView appeal={appeal} /> */}
            <h1>submit</h1>
          </Route>
        </Switch>
      </MotionToVacateContextProvider>
    </React.Fragment>
  );
};
