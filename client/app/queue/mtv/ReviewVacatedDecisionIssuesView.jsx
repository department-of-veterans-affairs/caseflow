import React, { useContext, useState } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../COPY';

import QueueFlowPage from '../components/QueueFlowPage';
import AmaIssueList from '../../components/AmaIssueList';
import DecisionIssues from '../components/DecisionIssues';
import { MotionToVacateContext } from './MotionToVacateContext';
import { RemoveDecisionIssueModal } from './RemoveDecisionIssueModal';

const validateForm = () => true;
const defaultState = { deleteModal: false,
  issueId: null,
  decisionIssue: null };

export const ReviewVacatedDecisionIssuesView = ({ appeal }) => {
  //   Not sure that we need this
  const issueErrors = {};

  const [ctx, setCtx] = useContext(MotionToVacateContext);
  const [state, setState] = useState(defaultState);

  const handleDelete = (issueId, decisionIssue) => {
    setState({
      ...state,
      deleteModal: true,
      issueId,
      decisionIssue
    });
  };

  const onCancelDelete = () =>
    setState({
      ...state,
      deleteModal: false,
      issueId: null
    });

  const onDeleteSubmit = () => {
    setCtx({
      ...ctx,
      decisionIssues: ctx.decisionIssues.filter((issue) => issue.id !== state.issueId)
    });

    setState({
      ...state,
      deleteModal: false,
      issueId: null,
      decisionIssue: null
    });
  };

  return (
    <QueueFlowPage
      validateForm={validateForm}
      appealId={appeal.externalId}
      getNextStepUrl={() => ctx.getNextUrl('review_vacatures')}
      getPrevStepUrl={() => ctx.getPrevUrl('review_vacatures')}
    >
      <h1>{COPY.MTV_CHECKOUT_REVIEW_VACATURES_TITLE}</h1>
      <p>{COPY.MTV_CHECKOUT_REVIEW_VACATURES_EXPLANATION}</p>
      <hr />
      <AmaIssueList requestIssues={appeal.issues} errorMessages={issueErrors}>
        <DecisionIssues
          decisionIssues={ctx.decisionIssues}
          //   openDecisionHandler={this.openDecisionHandler}
          openDeleteAddedDecisionIssueHandler={handleDelete}
        />
      </AmaIssueList>
      {state.deleteModal && <RemoveDecisionIssueModal onCancel={onCancelDelete} onSubmit={onDeleteSubmit} />}
    </QueueFlowPage>
  );
};

ReviewVacatedDecisionIssuesView.propTypes = {
  appeal: PropTypes.object.isRequired
};
