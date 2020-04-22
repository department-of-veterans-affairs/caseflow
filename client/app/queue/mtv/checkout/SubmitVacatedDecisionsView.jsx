import React, { useContext, useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { MotionToVacateContext } from './MotionToVacateContext';
import { useDispatch, useSelector } from 'react-redux';
import { editStagedAppeal, stageAppeal, setDecisionOptions } from '../../QueueActions';
import SubmitDecisionView from '../../SubmitDecisionView';
import { useParams } from 'react-router';
import DECISION_TYPES from '../../../../constants/APPEAL_DECISION_TYPES';
import { taskById } from '../../selectors';
import ApiUtil from '../../../util/ApiUtil';
import StringUtil from '../../../util/StringUtil';

const { capitalizeFirst, snakeCaseToCamelCase } = StringUtil;

const buildPayload = ({ adminActions, externalId, parentId }) => ({
  data: {
    tasks: adminActions.map(({ type, instructions }) => {
      // We need to submit an actual task name, so reformatting is necessary
      const taskName = `${capitalizeFirst(snakeCaseToCamelCase(type))}ColocatedTask`;

      return {
        instructions,
        type: taskName,
        external_id: externalId,
        parent_id: parentId
      };
    })
  }
});

export const SubmitVacatedDecisionsView = ({ appeal }) => {
  const [ctx] = useContext(MotionToVacateContext);
  const { appealId, taskId } = useParams();
  const dispatch = useDispatch();
  const [loading, setLoading] = useState(true);
  const task = useSelector((state) => taskById(state, { taskId }));

  useEffect(() => {
    // We need to update staged appeal in Redux so existing flow can continue
    dispatch(stageAppeal(appealId));
    dispatch(editStagedAppeal(appealId, { decisionIssues: ctx.decisionIssues }));
    dispatch(setDecisionOptions({ work_product: 'Decision' }));
    setLoading(false);
  }, [appeal, ctx.decisionIssues]);

  const handleSuccess = async () => {
    const { adminActions } = ctx;

    // TODO: Adjust this logic to account for rules re creating child tasks of tasks to which one isn't assigned
    // Currently attorney can't create child tasks of the judge task, which is what we're trying to do here

    // Create admin actions, if any exist with values set
    if (adminActions?.map((item) => Boolean(item.type)).length) {
      const { externalId } = appeal;
      const { parentId } = task;
      const payload = buildPayload({ adminActions, externalId, parentId });

      await ApiUtil.post('/tasks', payload);
    }
  };

  return loading ? null : (
    <SubmitDecisionView
      appealId={appealId}
      taskId={taskId}
      checkoutFlow={DECISION_TYPES.DRAFT_DECISION}
      nextStep="/queue"
      prevUrl={ctx.getPrevUrl('submit')}
      continueBtnText="Submit"
      onSuccess={handleSuccess}
    />
  );
};
SubmitVacatedDecisionsView.propTypes = {
  appeal: PropTypes.object.isRequired
};
