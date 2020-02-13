import React, { useContext, useState } from 'react';
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

  const closeModals = () => setState({ ...defaultState });

  const openAddIssueModal = (requestIssueId) => () => {
    setState({
      ...state,
      addIssueModal: true,
      requestIssueId
    });
  };

  const onAddIssueSubmit = () => {
    const requestIssue = appeal?.issues?.find((issue) => issue.id === ctx.requestIssueId);

    // Avoid potential errors, though this should never happen
    if (!requestIssue) {
      return;
    }

    const newDecisionIssue = {
      id: `temporary-id-${uuid.v4()}`,
      description: '',
      disposition: requestIssue.closed_status,
      benefit_type: requestIssue.program,
      diagnostic_code: requestIssue.diagnostic_code,
      request_issue_ids: [ctx.requestIssueId]
    };

    setCtx({
      ...ctx,
      decisionIssues: [...ctx.decisionIssues, newDecisionIssue]
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
      {state.addIssueModal && <AddDecisionIssueModal onCancel={closeModals} onSubmit={onAddIssueSubmit} />}
    </QueueFlowPage>
  );
};

AddDecisionIssuesView.propTypes = {
  appeal: PropTypes.object.isRequired,
  allowDelete: PropTypes.bool
};
