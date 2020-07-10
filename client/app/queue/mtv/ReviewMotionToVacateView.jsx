import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { MotionsAttorneyDisposition } from './MotionsAttorneyDisposition';

import { useDispatch, useSelector } from 'react-redux';
import { useParams, useRouteMatch, useHistory } from 'react-router-dom';

import { fetchJudges } from '../QueueActions';
import { submitMTVAttyReview } from './mtvActions';
import { taskById, appealWithDetailSelector } from '../selectors';
import { taskActionData } from '../utils';

export const ReviewMotionToVacateView = () => {
  const { taskId, appealId } = useParams();
  const match = useRouteMatch();
  const history = useHistory();
  const dispatch = useDispatch();

  const task = useSelector((state) => taskById(state, { taskId }));
  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));
  const judges = useSelector((state) => state.queue.judges);
  const { submitting } = useSelector((state) => state.mtv.attorneyView);

  const { selected } = taskActionData({ task,
    match });

  const judgeOptions = Object.values(judges).map(({ id: value, display_name: label }) => ({
    label,
    value
  }));

  const handleSubmit = async (review) => {
    const newTask = {
      ...review,
      parent_id: task.taskId,
      type: 'JudgeAddressMotionToVacateTask',
      external_id: appeal.externalId,
      assigned_to_type: 'User'
    };

    await dispatch(
      submitMTVAttyReview({
        appeal,
        newTask,
        history
      })
    );
  };

  useEffect(() => {
    if (!judgeOptions.length) {
      dispatch(fetchJudges());
    }
  });

  return (
    judges && (
      <MotionsAttorneyDisposition
        task={task}
        judges={judgeOptions}
        selectedJudge={selected}
        appeal={appeal}
        onSubmit={handleSubmit}
        submitting={submitting}
      />
    )
  );
};

ReviewMotionToVacateView.propTypes = {
  task: PropTypes.object,
  appeal: PropTypes.object,
  judges: PropTypes.object,
  fetchJudges: PropTypes.func,
  submitMTVAttyReview: PropTypes.func,
  error: PropTypes.bool
};

export default ReviewMotionToVacateView;
