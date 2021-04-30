import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { useFormContext } from 'react-hook-form';
import { capitalize } from 'lodash';

import Checkbox from 'app/components/Checkbox';
import format from 'date-fns/format';
import { parseISO } from 'date-fns';

const tableStyles = css({});

export const TaskSelectionTable = ({ tasks }) => {
  const { register } = useFormContext();

  const formattedTasks = useMemo(() => {
    return tasks.map((task) => ({
      ...task,
      status: capitalize(task.status),
      closedAt: format(parseISO(task.closedAt), 'MM/dd/yyyy'),
    }));
  }, [tasks]);

  console.log('tasks', tasks);

  return (
    <table className={`usa-table-borderless ${tableStyles}`}>
      <thead>
        <tr>
          <th>Select</th>
          <th>Task</th>
          <th>Status</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        {formattedTasks.map((task) =>
          task.hidden ? null : (
            <tr key={task.taskId}>
              <td>
                <Checkbox
                  name={`taskIds[${task.taskId}]`}
                  inputRef={register}
                  disabled={task.disabled}
                  hideLabel
                />
              </td>
              <td>{task.label}</td>
              <td>{task.status}</td>
              <td>{task.closedAt}</td>
            </tr>
          )
        )}
      </tbody>
    </table>
  );
};

TaskSelectionTable.propTypes = {
  tasks: PropTypes.array,
};
