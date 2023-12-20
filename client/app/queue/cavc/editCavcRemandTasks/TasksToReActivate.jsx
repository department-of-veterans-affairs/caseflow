import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useFormContext } from 'react-hook-form';
import { capitalize } from 'lodash';
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
import { TasksToReActivateSelectionTable } from './TasksToReActivateSelectionTable';

export const TasksToReActivate = ({ tasks, existingValues, setSelectedReActivateTaskIds }) => {
  const { control } = useFormContext();
  const fieldName = 'reActivateTaskIds';
  const [reActivateTaskIds, setReActivateTaskIds] = useState(existingValues?.reActivateTaskIds || []);

  const formattedTasks = useMemo(() => {
    return tasks.map((task) => ({
      ...task,
      taskId: parseInt(task.taskId, 10),
      status: capitalize(task.status),
      closedAt: task.closedAt ? format(parseISO(task.closedAt), 'MM/dd/yyyy') : null,
    }));
  }, [tasks]);

  setSelectedReActivateTaskIds(reActivateTaskIds);

  const handleCheck = (changedId, checked) => {
    if (checked) {
      setReActivateTaskIds([...reActivateTaskIds, changedId]);
    } else {
      setReActivateTaskIds(reActivateTaskIds.filter((taskId) => taskId !== changedId));
    }
    setSelectedReActivateTaskIds(reActivateTaskIds);

    return reActivateTaskIds;
  };

  return (
    <TasksToReActivateSelectionTable
      control={control}
      onCheckChange={handleCheck}
      tasks={formattedTasks}
      selectionField={fieldName}
      selectedReActivateTaskIds={reActivateTaskIds}
    />
  );
};

TasksToReActivate.propTypes = {
  tasks: PropTypes.array,
  existingValues: PropTypes.object,
  setSelectedReActivateTaskIds: PropTypes.func,
};

