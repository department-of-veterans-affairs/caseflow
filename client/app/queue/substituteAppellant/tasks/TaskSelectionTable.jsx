import React, { useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { Controller, useFormContext } from 'react-hook-form';
import { capitalize } from 'lodash';

import Checkbox from 'app/components/Checkbox';
import format from 'date-fns/format';
import { parseISO } from 'date-fns';

const tableStyles = css({});
const centerCheckboxPadding = css({ paddingTop: 'inherit' });

export const TaskSelectionTable = ({ tasks }) => {
  const { control, getValues, watch } = useFormContext();

  const formattedTasks = useMemo(() => {
    return tasks.map((task) => ({
      ...task,
      taskId: parseInt(task.taskId, 10),
      status: capitalize(task.status),
      closedAt: format(parseISO(task.closedAt), 'MM/dd/yyyy'),
    }));
  }, [tasks]);

  // Code from https://github.com/react-hook-form/react-hook-form/issues/1517#issuecomment-662386647
  const handleCheck = (changedId) => {
    const { taskIds: ids } = getValues();

    // if changedId is already in array of selected Ids, filter it out;
    // otherwise, return array with it included
    const newIds = ids?.includes(changedId) ?
      ids?.filter((id) => id !== changedId) :
      [...(ids ?? []), changedId];

    // this will get set as new value for taskIds by react hook form
    return newIds;
  };

  // We use this to set `defaultChecked` for the task checkboxes
  const selectedTaskIds = watch('taskIds');

  // Error handling that should never be needed with real production data
  if (!formattedTasks.length) {
    return <p>There is no task available to reopen</p>;
  }

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
        <Controller
          control={control}
          name="taskIds"
          render={({ onChange }) =>
            formattedTasks.map((task) =>
              task.hidden ? null : (
                <tr key={task.taskId}>
                  <td {...centerCheckboxPadding}>
                    <Checkbox
                      onChange={() => onChange(handleCheck(task.taskId))}
                      defaultValue={selectedTaskIds?.includes(task.taskId)}
                      name={`taskIds[${task.taskId}]`}
                      disabled={task.disabled}
                      hideLabel
                    />
                  </td>
                  <td>{task.label}</td>
                  <td>{task.status}</td>
                  <td>{task.closedAt}</td>
                </tr>
              )
            )
          }
        />
      </tbody>
    </table>
  );
};

TaskSelectionTable.propTypes = {
  tasks: PropTypes.array,
};
