import React, { useState } from 'react';

import { useSelector, useDispatch } from 'react-redux';
import { useRouteMatch, useParams, useHistory } from 'react-router-dom';

import { taskById, appealWithDetailSelector } from '../selectors';
import { MTVJudgeDisposition } from './MTVJudgeDisposition';
import { JUDGE_RETURN_TO_LIT_SUPPORT } from '../../../constants/TASK_ACTIONS';
import { submitMTVJudgeDecision } from './mtvActions';
import { taskActionData } from '../utils';

export const AddressMotionToVacateView = () => {
  const { taskId, appealId } = useParams();
  const match = useRouteMatch();
  const history = useHistory();
  const dispatch = useDispatch();
  const [submitting, setSubmitting] = useState(false);

  const task = useSelector((state) => taskById(state, { taskId }));
  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));

  const { selected, options } = taskActionData({ task,
    match });

  const attyOptions = options.map(({ value, label }) => ({
    label: label + (selected && value === selected.id ? ' (Orig. Attorney)' : ''),
    value
  }));

  const handleSubmit = (result) => {
    setSubmitting(true);
    dispatch(
      submitMTVJudgeDecision(result, {
        history,
        appeal
      })
    );
  };

  return (
    <MTVJudgeDisposition
      task={task}
      attorneys={attyOptions}
      selectedAttorney={selected}
      appeal={appeal}
      onSubmit={handleSubmit}
      returnToLitSupportLink={`${match.url}/${JUDGE_RETURN_TO_LIT_SUPPORT.value}`}
      submitting={submitting}
    />
  );
};

export default AddressMotionToVacateView;
