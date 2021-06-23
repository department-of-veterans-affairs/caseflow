import React, { useContext, useState, useMemo } from 'react';
import PropTypes from 'prop-types';

import COPY from '../../../../COPY';

import QueueFlowPage from '../../components/QueueFlowPage';
import AmaIssueList from '../../../components/AmaIssueList';
import DecisionIssues from '../../components/DecisionIssues';
import { MotionToVacateContext } from './MotionToVacateContext';
import { AddEditDecisionIssueModal } from './AddEditDecisionIssueModal';
import uuid from 'uuid';
import { RemoveDecisionIssueModal } from './RemoveDecisionIssueModal';
import { useRouteMatch } from 'react-router';

const validateForm = () => true;
const defaultState = {
  editIssueModal: false,
  deleteModal: false,
  operation: 'add',
  requestIssueId: null,
  decisionIssue: null
};

const hideEdit = ({ decisionIssue }) => decisionIssue?.disposition === 'vacated';

export const AddDecisionIssuesView = ({ appeal }) => {
  const [ctx, setCtx] = useContext(MotionToVacateContext);
  const [state, setState] = useState(defaultState);
  const { url } = useRouteMatch();

  const connectedRequestIssues = useMemo(
    () =>
      appeal.issues.filter((issue) => {
        // eslint-disable-next-line camelcase
        return state?.decisionIssue?.request_issue_ids?.includes(issue.id);
      }),
    [state.decisionIssue, appeal.issues]
  );

  const closeModals = () => setState({ ...defaultState });

  const handleDelete = (issueId, decisionIssue) => {
    setState({
      ...state,
      deleteModal: true,
      issueId,
      decisionIssue
    });
  };

  const onDeleteSubmit = () => {
    setCtx({
      ...ctx,
      decisionIssues: ctx.decisionIssues.filter((issue) => issue.id !== state?.decisionIssue?.id)
    });

    closeModals();
  };

  const openEditIssueModal = (requestIssueId, decisionIssue) => () => {
    const requestIssue = appeal?.issues?.find((issue) => issue.id === requestIssueId);
    const newDecisionIssue = {
      id: `temporary-id-${uuid.v4()}`,
      description: '',
      disposition: '',
      benefit_type: requestIssue.program,
      diagnostic_code: requestIssue.diagnostic_code,
      request_issue_ids: [requestIssueId]
    };

    setState({
      ...state,
      editIssueModal: true,
      requestIssueId,
      decisionIssue: decisionIssue || newDecisionIssue,
      operation: decisionIssue ? 'edit' : 'add'
    });
  };

  const onIssueSubmit = (decisionIssue) => {
    // Make sure we don't duplicate when editing
    const issues = ctx.decisionIssues.filter((issue) => issue.id !== decisionIssue.id);

    setCtx({
      ...ctx,
      decisionIssues: [...issues, decisionIssue]
    });

    closeModals();
  };

  const hasRemandedIssues = useMemo(() => {
    return ctx.decisionIssues.some((issue) => issue.disposition === 'remanded');
  }, [ctx.decisionIssues]);

  // Add conditional based on existence of remanded issues
  const remandUrl = url.replace('add_decisions', 'remand_reasons');
  const getNextStepUrl = () => hasRemandedIssues ? remandUrl : ctx.getNextUrl('add_decisions');

  return (
    <QueueFlowPage
      validateForm={validateForm}
      appealId={appeal.externalId}
      getNextStepUrl={getNextStepUrl}
      getPrevStepUrl={() => ctx.getPrevUrl('add_decisions')}
    >
      <h1>{COPY.MTV_CHECKOUT_ADD_DECISIONS_TITLE}</h1>
      <p>{COPY.MTV_CHECKOUT_ADD_DECISIONS_EXPLANATION}</p>
      <hr />
      <AmaIssueList requestIssues={appeal.issues} errorMessages={{}}>
        <DecisionIssues
          decisionIssues={ctx.decisionIssues}
          openDecisionHandler={openEditIssueModal}
          openDeleteAddedDecisionIssueHandler={handleDelete}
          hideDelete={hideEdit}
          hideEdit={hideEdit}
        />
      </AmaIssueList>
      {state.editIssueModal && (
        <AddEditDecisionIssueModal
          appeal={appeal}
          decisionIssue={state.decisionIssue}
          connectedRequestIssues={connectedRequestIssues}
          operation={state.operation}
          onCancel={closeModals}
          onSubmit={onIssueSubmit}
        />
      )}
      {state.deleteModal && <RemoveDecisionIssueModal onCancel={closeModals} onSubmit={onDeleteSubmit} />}
    </QueueFlowPage>
  );
};

AddDecisionIssuesView.propTypes = {
  appeal: PropTypes.object.isRequired,
  allowDelete: PropTypes.bool
};
