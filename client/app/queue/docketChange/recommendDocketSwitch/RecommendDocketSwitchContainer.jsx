import React from 'react';
import { useSelector } from 'react-redux';
import { useParams } from 'react-router';

import { taskById, appealWithDetailSelector } from '../../selectors';
import { RecommendDocketSwitchForm } from './RecommendDocketSwitchForm';

export const RecommendDocketSwitchContainer = () => {
  const { taskId, appealId } = useParams();

  const task = useSelector((state) => taskById(state, { taskId }));
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const cancelLink = `/queue/appeals/${task.externalAppealId}`;

  return <RecommendDocketSwitchForm cancelLink={cancelLink} />;
};
