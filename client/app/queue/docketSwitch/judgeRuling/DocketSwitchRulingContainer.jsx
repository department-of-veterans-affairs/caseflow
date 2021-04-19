import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams, useRouteMatch } from 'react-router';
import { taskById, appealWithDetailSelector } from 'app/queue/selectors';
import { taskActionData } from 'app/queue/utils';
import DISPOSITIONS from 'constants/DOCKET_SWITCH_DISPOSITIONS';
import { DocketSwitchRulingForm } from './DocketSwitchRulingForm';
import {
  DOCKET_SWITCH_RULING_SUCCESS_TITLE,
  DOCKET_SWITCH_RULING_SUCCESS_MESSAGE,
} from '../../../../COPY';

import { sprintf } from 'sprintf-js';
import { showSuccessMessage } from '../../uiReducer/uiActions';
import { addressDocketSwitchRuling } from '../docketSwitchSlice';

export const formatDocketSwitchRuling = ({
  disposition,
  hyperlink,
  context,
}) => {
  const parts = [];

  parts.push(`I am proceeding with a ${DISPOSITIONS[disposition].judgeRulingText}.`);
  if (hyperlink) {
    parts.push(`**Signed ruling letter:** [View link](${hyperlink})`);
  }
  parts.push(context);

  return parts.join('  \n  \n');
};

export const DocketSwitchRulingContainer = () => {
  const { appealId, taskId } = useParams();
  const { goBack, push } = useHistory();
  const dispatch = useDispatch();
  const task = useSelector((state) => taskById(state, { taskId }));
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );
  const match = useRouteMatch();
  const { selected, options } = taskActionData({ task, match });

  // Use regex to pull draft letter hyperlink out from the current task's instructions, if possible.
  // It will be reused in the subsequent task's instructions.
  const draftInstructions = task.instructions.join('\n');
  const hyperlink = (/\*\*Draft letter:\*\* \[[^\]]+\]\(([^)]+)\)/).exec(draftInstructions)?.[1];

  // eslint-disable-next-line no-console
  const handleSubmit = async (formData) => {
    const instructions = formatDocketSwitchRuling({ hyperlink, ...formData });
    const { disposition } = formData;
    const dispositionType = DISPOSITIONS[disposition].dispositionType;
    const taskType = `DocketSwitch${dispositionType}Task`;

    const data = {
      task_id: taskId,
      new_task_type: taskType,
      instructions,
      assigned_to_user_id: formData.attorney.value,
    };

    const successMessage = {
      title: sprintf(DOCKET_SWITCH_RULING_SUCCESS_TITLE, dispositionType.toLowerCase(), appeal.appellantFullName),
      detail: DOCKET_SWITCH_RULING_SUCCESS_MESSAGE,
    };

    try {
      await dispatch(addressDocketSwitchRuling(data));
      dispatch(showSuccessMessage(successMessage));
      push('/queue');
    } catch (error) {
      // Perhaps show an alert that indicates error, advise trying again...?
      console.error('Error saving task', error);
    }
  };

  return (
    <DocketSwitchRulingForm
      onCancel={goBack}
      onSubmit={handleSubmit}
      clerkOfTheBoardAttorneys={options}
      defaultAttorneyId={selected}
      appellantName={appeal.appellantFullName}
      instructions={task.instructions}
    />
  );
};
