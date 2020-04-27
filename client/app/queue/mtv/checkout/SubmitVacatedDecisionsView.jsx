import React, { useContext, useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { MotionToVacateContext } from './MotionToVacateContext';
import { useDispatch } from 'react-redux';
import { editStagedAppeal, stageAppeal, setDecisionOptions } from '../../QueueActions';
import SubmitDecisionView from '../../SubmitDecisionView';
import { useParams } from 'react-router';
import DECISION_TYPES from '../../../../constants/APPEAL_DECISION_TYPES';

export const SubmitVacatedDecisionsView = ({ appeal }) => {
  const [ctx] = useContext(MotionToVacateContext);
  const { appealId, taskId } = useParams();
  const dispatch = useDispatch();
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // We need to update staged appeal in Redux so existing flow can continue
    dispatch(stageAppeal(appealId));
    dispatch(editStagedAppeal(appealId, { decisionIssues: ctx.decisionIssues }));
    dispatch(setDecisionOptions({ work_product: 'Decision' }));
    setLoading(false);
  }, [appeal, ctx.decisionIssues]);

  return loading ? null : (
    <SubmitDecisionView
      appealId={appealId}
      taskId={taskId}
      checkoutFlow={DECISION_TYPES.DRAFT_DECISION}
      nextStep="/queue"
      prevUrl={ctx.getPrevUrl('submit')}
      continueBtnText="Submit"
    />
  );
};
SubmitVacatedDecisionsView.propTypes = {
  appeal: PropTypes.object.isRequired
};
