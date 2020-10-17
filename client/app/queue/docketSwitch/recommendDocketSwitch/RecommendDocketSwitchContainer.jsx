import React, { useEffect, useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams } from 'react-router';
import { fetchJudges } from '../../QueueActions';

import { appealWithDetailSelector } from '../../selectors';
import { RecommendDocketSwitchForm } from './RecommendDocketSwitchForm';

export const RecommendDocketSwitchContainer = () => {
  const { appealId } = useParams();
  const { goBack } = useHistory();
  const dispatch = useDispatch();

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

  // We want to default the judge selection to the VLJ currently assigned to the case, if exists
  const defaultJudgeId = useMemo(() => {
    // eslint-disable-next-line no-undefined
    return appeal.assignedJudge?.id ?? undefined;
  }, [judges, appeal]);

  // eslint-disable-next-line no-console
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
      appellantName={appeal.appellantFullName}
    />
  );
};
