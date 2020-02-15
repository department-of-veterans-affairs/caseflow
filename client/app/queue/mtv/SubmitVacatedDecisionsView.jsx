import React, { useContext, useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { MotionToVacateContext } from './MotionToVacateContext';
import { useDispatch } from 'react-redux';
import { editStagedAppeal, stageAppeal } from '../QueueActions';
import SubmitDecisionView from '../SubmitDecisionView';
import { useParams } from 'react-router';
import DECISION_TYPES from '../../../constants/APPEAL_DECISION_TYPES';

export const SubmitVacatedDecisionsView = ({ appeal }) => {
  const [ctx] = useContext(MotionToVacateContext);
  const { taskId } = useParams();
  const dispatch = useDispatch();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // dispatch to editStagedAppeal to update appeal so existing flow can continue
    dispatch(stageAppeal(appeal.id));
    dispatch(editStagedAppeal(appeal.id, { decisionIssues: ctx.decisionIssues }));
    setLoading(false);
  }, [appeal, ctx.decisionIssues]);

  return loading ? null : (
    <SubmitDecisionView
      appealId={appeal.id}
      taskId={taskId}
      checkoutFlow={DECISION_TYPES.DRAFT_DECISION}
      nextStep="/queue"
    />
  );
};
SubmitVacatedDecisionsView.propTypes = {
  appeal: PropTypes.object.isRequired
};
