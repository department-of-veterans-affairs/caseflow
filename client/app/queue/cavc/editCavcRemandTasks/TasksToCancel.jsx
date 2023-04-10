import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useFormContext } from 'react-hook-form';
import { capitalize } from 'lodash';
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
import { TasksToCancelSelectionTable } from './TasksToCancelSelectionTable';

export const TasksToCancel = ({ tasks, existingValues, setSelectedCancelTaskIds }) => {
  const { control } = useFormContext();
  const fieldName = 'cancelTaskIds';
  const [cancelTaskIds, setCancelTaskIds] = useState(existingValues?.cancelTaskIds || []);

  const formattedTasks = useMemo(() => {
    return tasks.map((task) => ({
      ...task,
      taskId: parseInt(task.taskId, 10),
      status: capitalize(task.status),
      createdAt: format(parseISO(task.createdAt), 'MM/dd/yyyy'),
    }));
  }, [tasks]);

  setSelectedCancelTaskIds(cancelTaskIds);

  const handleCheck = (changedId, checked) => {
    if (checked) {
      setCancelTaskIds(cancelTaskIds.filter((taskId) => taskId !== changedId));
    } else {
      setCancelTaskIds([...cancelTaskIds, changedId]);
    }
    setSelectedCancelTaskIds(cancelTaskIds);

    return cancelTaskIds;
  };

  return (
    <TasksToCancelSelectionTable
      control={control}
      onCheckChange={handleCheck}
      tasks={formattedTasks}
      selectionField={fieldName}
      selectedCancelTaskIds={cancelTaskIds}
    />
  );
};

TasksToCancel.propTypes = {
  tasks: PropTypes.array,
  existingValues: PropTypes.object,
  setSelectedCancelTaskIds: PropTypes.func,
};

