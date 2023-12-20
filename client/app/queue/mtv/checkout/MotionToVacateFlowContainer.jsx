import React, { useMemo } from 'react';
import { useSelector } from 'react-redux';
import { useParams, useRouteMatch, Switch, Route, generatePath } from 'react-router';
import { appealWithDetailSelector } from '../../selectors';
import { MotionToVacateContextProvider } from './MotionToVacateContext';
import { AddDecisionIssuesView } from './AddDecisionIssuesView';
import { ReviewVacatedDecisionIssuesView } from './ReviewVacatedDecisionIssuesView';
import { getSteps, getNextStep, getPrevStep } from './mtvCheckoutSteps';
import { SubmitVacatedDecisionsView } from './SubmitVacatedDecisionsView';
import { MotionToVacateCheckoutProgressBar } from './MotionToVacateCheckoutProgressBar';
import { ReturnToJudgeModalContainer } from './returnToJudge/ReturnToJudgeModalContainer';
import { REVIEW_VACATE_RETURN_TO_JUDGE } from '../../../../constants/TASK_ACTIONS';
import { AddAdminActionsView } from './AddAdminActionsView';
import { AddRemandReasonsView } from './AddRemandReasonsView';

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
        <React.Fragment>
          <Switch>
            <Route path={`${path}/review_vacatures`}>
              <MotionToVacateCheckoutProgressBar steps={steps} current="review_vacatures" />
              <ReviewVacatedDecisionIssuesView appeal={appeal} />
            </Route>

            <Route path={`${path}/add_decisions`}>
              <MotionToVacateCheckoutProgressBar steps={steps} current="add_decisions" />
              <AddDecisionIssuesView appeal={appeal} />
            </Route>

            <Route path={`${path}/remand_reasons`}>
              <MotionToVacateCheckoutProgressBar steps={steps} current="add_decisions" />
              <AddRemandReasonsView appeal={appeal} />
            </Route>

            <Route path={`${path}/admin_actions`}>
              <MotionToVacateCheckoutProgressBar steps={steps} current="admin_actions" />
              <AddAdminActionsView appeal={appeal} />
            </Route>

            <Route path={`${path}/submit`}>
              <MotionToVacateCheckoutProgressBar steps={steps} current="submit" />
              <SubmitVacatedDecisionsView appeal={appeal} />
            </Route>
          </Switch>
          <Switch>
            <Route path={`${path}/review_vacatures/${REVIEW_VACATE_RETURN_TO_JUDGE.value}`}>
              <ReturnToJudgeModalContainer />
            </Route>
          </Switch>
        </React.Fragment>
      </MotionToVacateContextProvider>
    </React.Fragment>
  );
};
