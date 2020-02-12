import React, { useContext, useState } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY';

import QueueFlowPage from '../components/QueueFlowPage';
import AmaIssueList from '../../components/AmaIssueList';
import DecisionIssues from '../components/DecisionIssues';
import { MotionToVacateContext } from './MotionToVacateContext';
import { AddDecisionIssueModal } from './AddDecisionIssueModal';

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
    setCtx({
      ...ctx,
      decisionIssues: ctx.decisionIssues.filter((issue) => issue.id !== state.requestIssueId)
    });

    closeModals();
  };

  return (
    <QueueFlowPage
      validateForm={validateForm}
      appealId={appeal.externalId}
      getNextStepUrl={() => ctx.getNextUrl('review_vacatures')}
      getPrevStepUrl={() => ctx.getPrevUrl('review_vacatures')}
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
