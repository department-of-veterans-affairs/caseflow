import React, { useEffect, useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import { fetchJudges } from '../../QueueActions';

import { taskById, appealWithDetailSelector } from '../../selectors';
import { RecommendDocketSwitchForm } from './RecommendDocketSwitchForm';

export const RecommendDocketSwitchContainer = () => {
  const { taskId, appealId } = useParams();
  const { goBack } = useHistory();
  const dispatch = useDispatch();

  const task = useSelector((state) => taskById(state, { taskId }));
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const judges = useSelector((state) => state.queue.judges);
  const judgeOptions = useMemo(
    () =>
      Object.values(judges).map(({ id: value, display_name: label }) => ({
        label,
        value,
      })),
    [judges]
  );

  // TODO - add logic to pull this from task tree
  const defaultJudgeId = useMemo(() => 3, [judges, appeal]);

  const handleSubmit = (formData) => console.log('handleSubmit', formData);

  useEffect(() => {
    if (!judgeOptions.length) {
      dispatch(fetchJudges());
    }
  });

  return (
    <RecommendDocketSwitchForm
      onCancel={goBack}
      onSubmit={handleSubmit}
      judgeOptions={judgeOptions}
      defaultJudgeId={defaultJudgeId}
    />
  );
};
