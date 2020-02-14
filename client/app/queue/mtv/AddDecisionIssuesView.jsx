import React, { useContext, useState, useMemo } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY';

import QueueFlowPage from '../components/QueueFlowPage';
import AmaIssueList from '../../components/AmaIssueList';
import DecisionIssues from '../components/DecisionIssues';
import { MotionToVacateContext } from './MotionToVacateContext';
import { AddDecisionIssueModal } from './AddDecisionIssueModal';
import uuid from 'uuid';

const validateForm = () => true;
const defaultState = {
  addIssueModal: false,
  requestIssueId: null,
  decisionIssue: null
};

export const AddDecisionIssuesView = ({ appeal }) => {
  const [ctx, setCtx] = useContext(MotionToVacateContext);
  const [state, setState] = useState(defaultState);

  const connectedRequestIssues = useMemo(
    () =>
      appeal.issues.filter((issue) => {
        return ctx.decisionIssue && ctx.decisionIssue.request_issue_ids.includes(issue.id);
      }),
    [ctx.decisionIssue, appeal.issues]
  );

  const closeModals = () => setState({ ...defaultState });

  const openAddIssueModal = (requestIssueId, decisionIssue) => () => {
    const requestIssue = appeal?.issues?.find((issue) => issue.id === requestIssueId);
    const newDecisionIssue = {
      id: `temporary-id-${uuid.v4()}`,
      description: '',
      disposition: requestIssue.closed_status,
      benefit_type: requestIssue.program,
      diagnostic_code: requestIssue.diagnostic_code,
      request_issue_ids: [requestIssueId]
    };

    setState({
      ...state,
      addIssueModal: true,
      requestIssueId,
      decisionIssue: decisionIssue || newDecisionIssue
    });
  };

  const onAddIssueSubmit = () => {
    setCtx({
      ...ctx,
      decisionIssues: [...ctx.decisionIssues, ctx.decisionIssue]
    });

    closeModals();
  };

  return (
    <QueueFlowPage
      validateForm={validateForm}
      appealId={appeal.externalId}
      getNextStepUrl={() => ctx.getNextUrl('add_decisions')}
      getPrevStepUrl={() => ctx.getPrevUrl('add_decisions')}
    >
      <h1>{COPY.MTV_CHECKOUT_ADD_DECISIONS_TITLE}</h1>
      <p>{COPY.MTV_CHECKOUT_ADD_DECISIONS_EXPLANATION}</p>
      <hr />
      <AmaIssueList requestIssues={appeal.issues} errorMessages={{}}>
        <DecisionIssues decisionIssues={ctx.decisionIssues} openDecisionHandler={openAddIssueModal} hideEdit />
      </AmaIssueList>
      {state.addIssueModal && (
        <AddDecisionIssueModal
          appeal={appeal}
          decisionIssue={state.decisionIssue}
          connectedRequestIssues={connectedRequestIssues}
          onCancel={closeModals}
          onSubmit={onAddIssueSubmit}
        />
      )}
    </QueueFlowPage>
  );
};

AddDecisionIssuesView.propTypes = {
  appeal: PropTypes.object.isRequired,
  allowDelete: PropTypes.bool
};
