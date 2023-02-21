import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { Controller } from 'react-hook-form';

import StringUtil from 'app/util/StringUtil';
import Checkbox from 'app/components/Checkbox';

const tableStyles = css({});
const centerCheckboxPadding = css({ paddingTop: 'inherit' });

export const TaskSelectionTable = ({
  control,
  onCheckChange,
  selectionField,
  selectedTaskIds,
  tasks,
}) => {
  // Error handling that should never be needed with real production data
  if (!tasks.length) {
    return <p>There is no task available to reopen</p>;
  }

  const formatStatus = (status) => StringUtil.snakeCaseToCapitalized(status);

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
          name={selectionField}
          render={({ onChange }) =>
            tasks.map((task) =>
              task.hidden ? null : (
                <tr key={task.taskId}>
                  <td {...centerCheckboxPadding}>
                    <Checkbox
                      onChange={() => onChange(onCheckChange(task.taskId))}
                      value={selectedTaskIds?.includes(task.taskId)}
                      name={`${selectionField}[${task.taskId}]`}
                      disabled={task.disabled}
                      label={
                        <>
                          &nbsp;
                          <span className="usa-sr-only">
                            Select {task.label}
                          </span>
                        </>
                      }
                    />
                  </td>
                  <td>{task.label.replace('Task', '')}</td>
                  <td>{formatStatus(task.status)}</td>
                  <td>{task.closedAt || task.createdAt}</td>
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
  control: PropTypes.object,
  onCheckChange: PropTypes.func,
  tasks: PropTypes.array,
  selectedTaskIds: PropTypes.array,
  selectionField: PropTypes.string,
};
