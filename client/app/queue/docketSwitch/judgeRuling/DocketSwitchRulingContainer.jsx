import React, { useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams, useRouteMatch } from 'react-router';
import { taskById, appealWithDetailSelector } from '../../selectors';
import { taskActionData } from '../../utils';
import { DISPOSITIONS } from '../constants';
import { createDocketSwitchGrantedTask, createDocketSwitchDeniedTask } from './docketSwitchRulingSlice';
import { DocketSwitchRulingForm } from './DocketSwitchRulingForm';

export const formatDocketSwitchRuling = ({
  disposition,
  hyperlink,
  context,
}) => {
  const parts = [];

  parts.push(`I am proceeding with a:\n ${DISPOSITIONS[disposition].judgeRulingText}.`);
  parts.push(`Signed ruling letter:\n ${hyperlink}`);
  parts.push(`Context/Instructions:\n ${context}`);

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

  // eslint-disable-next-line no-console
  const handleSubmit = async (formData) => {
    const instructions = formatDocketSwitchRuling({ ...formData });
    const { disposition } = formData;
    const dispositionType = DISPOSITIONS[disposition].dispositionType;
    const taskType = `DocketSwitch${dispositionType}Task`;

    const newTask = {
      parent_id: taskId,
      type: taskType,
      external_id: appeal.externalId,
      instructions,
      assigned_to_id: selected.value,
      assigned_to_type: 'User',
    };

    const data = {
      tasks: [newTask],
    };

    try {
      if (dispositionType == "Granted") {
        await dispatch(createDocketSwitchGrantedTask(data));
      } else if (dispositionType == "Denied") {
        await dispatch(createDocketSwitchDeniedTask(data));
      };

      // Add logic for success banner
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
