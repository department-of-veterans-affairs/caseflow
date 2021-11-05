import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { useFormContext } from 'react-hook-form';
import { capitalize } from 'lodash';
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
import { TaskSelectionTable } from './TaskSelectionTable';

export const TasksToCancel = ({ tasks }) => {
  const { control, getValues, watch } = useFormContext();
  const fieldName = 'openTaskIds';

  const formattedTasks = useMemo(() => {
    return tasks.map((task) => ({
      ...task,
      taskId: parseInt(task.taskId, 10),
      status: capitalize(task.status),
      createdAt: format(parseISO(task.createdAt), 'MM/dd/yyyy'),
    }));
  }, [tasks]);

  // We use this to set `defaultChecked` for the task checkboxes
  const selectedTaskIds = watch(fieldName);

  // Code from https://github.com/react-hook-form/react-hook-form/issues/1517#issuecomment-662386647
  const handleCheck = (changedId) => {
    const { [fieldName]: ids } = getValues();
    const selectedTasks = tasks.filter((task) => ids.includes(Number(task.taskId)));
    const wasJustChecked = !ids?.includes(changedId);

    // if changedId is already in array of selected Ids, filter it out;
    // otherwise, return array with it included, but exclude any whose parents are deselected
    return wasJustChecked ?
      [...ids, changedId] :
      selectedTasks
          ?.filter(
            (task) => Number(task.taskId) !== changedId && task.parentId !== changedId
          )
          .map((task) => Number(task.taskId));
  };

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

TasksToCancel.propTypes = {
  tasks: PropTypes.array,
};

