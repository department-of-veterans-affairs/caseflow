import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams, useRouteMatch } from 'react-router';
import { appealWithDetailSelector, rootTasksForAppeal, taskById } from 'app/queue/selectors';
import { taskActionData } from 'app/queue/utils';

import DISPOSITIONS from 'constants/DOCKET_SWITCH_DISPOSITIONS';

import { RecommendDocketSwitchForm } from './RecommendDocketSwitchForm';
import {
  DOCKET_SWITCH_RECOMMENDATION_SUCCESS_TITLE,
  DOCKET_SWITCH_RECOMMENDATION_SUCCESS_MESSAGE,
} from 'app/../COPY';

import { sprintf } from 'sprintf-js';
import { showSuccessMessage } from 'app/queue/uiReducer/uiActions';
import { completeTask, createDocketSwitchRulingTask } from '../docketSwitchSlice';

// This takes form data and generates Markdown-formatted text to be saved as task instructions
export const formatDocketSwitchRecommendation = ({
  summary,
  timely,
  disposition,
  hyperlink,
}) => {
  const parts = [];

  const timelyCaps = timely[0].toUpperCase() + timely.substring(1);

  parts.push(`**Summary:** ${summary}`);
  parts.push(`**Is this a timely request:** ${timelyCaps}`);
  parts.push(`**Recommendation:** ${DISPOSITIONS[disposition].displayText}`);
  parts.push(`**Draft letter:** ${hyperlink}`);

  // Separate each chunk by two line breaks
  return parts.join('  \n  \n');
};

export const RecommendDocketSwitchContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();

  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));
  const rootTask = useSelector((state) => rootTasksForAppeal(state, { appealId }))[0];
  const task = useSelector((state) => taskById(state, { taskId }));

  const match = useRouteMatch();
  const options = taskActionData({ task, match })?.options;

  // eslint-disable-next-line no-console
  const handleSubmit = async (formData) => {

    const instructions = formatDocketSwitchRecommendation({ ...formData });
    const newTask = {
      parent_id: rootTask.taskId,
      type: 'DocketSwitchRulingTask',
      external_id: appeal.externalId,
      instructions,
      assigned_to_id: formData.judge.value,
      assigned_to_type: 'User',
    };

    const data = {
      tasks: [newTask],
    };

    const successMessage = {
      title: sprintf(DOCKET_SWITCH_RECOMMENDATION_SUCCESS_TITLE, appeal.appellantFullName, formData.judge.label),
      detail: DOCKET_SWITCH_RECOMMENDATION_SUCCESS_MESSAGE,
    };

    try {
      await dispatch(createDocketSwitchRulingTask(data));

      await dispatch(completeTask({ taskId }));

      dispatch(showSuccessMessage(successMessage));
      push('/queue');
    } catch (error) {
      // Perhaps show an alert that indicates error, advise trying again...?
      console.error('Error saving task', error);
    }
  };

  return (
    <RecommendDocketSwitchForm
      onCancel={goBack}
      onSubmit={handleSubmit}
      judgeOptions={options}
      defaultJudgeId={null}
      appellantName={appeal.appellantFullName}
    />
  );
};
