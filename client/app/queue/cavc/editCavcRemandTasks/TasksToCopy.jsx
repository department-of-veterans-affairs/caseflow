import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { useFormContext } from 'react-hook-form';
import { capitalize } from 'lodash';
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
import { TaskSelectionTable } from './TaskSelectionTable';
import { disabledTasksBasedOnSelections } from './utils';

export const TasksToCopy = ({ tasks }) => {
  const { control, getValues, watch } = useFormContext();
  const fieldName = 'closedTaskIds';

  const formattedTasks = useMemo(() => {
    return tasks.map((task) => ({
      ...task,
      taskId: parseInt(task.taskId, 10),
      status: capitalize(task.status),
      closedAt: task.closedAt ? format(parseISO(task.closedAt), 'MM/dd/yyyy') : null,
    }));
  }, [tasks]);

  // Code from https://github.com/react-hook-form/react-hook-form/issues/1517#issuecomment-662386647
  const handleCheck = (changedId) => {
    const { [fieldName]: ids } = getValues();
    const wasJustChecked = !ids?.includes(changedId);
    const nonDistributionTasks = tasks.filter((task) => task.type !== 'DistributionTask');
    // eslint-disable-next-line max-len
    const toDisable = disabledTasksBasedOnSelections({ tasks: nonDistributionTasks, selectedTaskIds: [...ids, changedId] });
    const toBeDisabledIds = wasJustChecked ? toDisable.filter((task) => task.disabled).
      map((task) => parseInt(task.taskId, 10)) : [];

    // if changedId is already in array of selected Ids, filter it out;
    // otherwise, return array with it included
    return wasJustChecked ?
      [...(ids.filter((id) => !toBeDisabledIds.includes(id)) ?? []), changedId] :
        ids?.filter((id) => id !== changedId);
  };

  // We use this to set `defaultChecked` for the task checkboxes
  const selectedTaskIds = watch(fieldName);

  return (
    <TaskSelectionTable
      control={control}
      onCheckChange={handleCheck}
      tasks={formattedTasks}
      selectedTaskIds={selectedTaskIds}
      selectionField={fieldName}
    />
  );
};

TasksToCopy.propTypes = {
  tasks: PropTypes.array,
};

