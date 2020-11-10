import React, { useMemo } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { useHistory, useParams, useRouteMatch } from 'react-router';

// import { useRouteMatch, useParams, useHistory } from 'react-router-dom';
// import { fetchJudges } from '../../QueueActions';

// import { appealWithDetailSelector } from '../../selectors';
import { taskById, appealWithDetailSelector } from '../../selectors';
import { dispositions } from '../constants';
import { createDocketSwitchRulingTask } from './DocketSwitchRulingSlice';
import { DocketSwitchRulingForm } from './DocketSwitchRulingForm';
import { taskActionData } from '../../utils';

export const formatDocketSwitchRuling = ({
  disposition,
  hyperlink,
  context,
}) => {
  const parts = [];

  parts.push(`I am proceeding with a:\n ${dispositions[disposition].displayText}.`);
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
  const { selected, options } = taskActionData({ task,
    match });

  // const attorneyOptions = options.map(({ value, label }) => ({
  //   label: label,
  //   value
  // }));
  //
  // const attorneyOptions = useMemo(
  //   () =>
  //     Object.values(options).map(({ id: value, display_name: label }) => ({
  //       label,
  //       value,
  //     })),
  //   [judges]
  // );

  // eslint-disable-next-line no-console
  const handleSubmit = async (formData) => {
    const instructions = formatDocketSwitchRuling({ ...formData });
    const newTask = {
      parent_id: taskId,
      type: 'GrantedDocketSwitchTask',
      external_id: appeal.externalId,
      instructions,
      assigned_to_id: selected.value,
      assigned_to_type: 'User',
    };

    const data = {
      tasks: [newTask],
    };

    try {
      await dispatch(createDocketSwitchRulingTask(data));

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
