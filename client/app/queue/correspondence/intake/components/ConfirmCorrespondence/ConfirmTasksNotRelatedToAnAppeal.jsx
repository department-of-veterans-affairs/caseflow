import React from 'react';
import { useSelector } from 'react-redux';

const ConfirmTasksNotRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);

  const rowObjects = tasks.map((task) => {
    return (
      <tr key={task.id} className="corr">
        <td
          className="td1">
          {task.label}
        </td>
        <td className="td2">
          {task.content}
        </td>
      </tr>
    );
  });

  const renderNonRelatedTask = () => {
    if (tasks.length === 0) {
      const rendererOfNonRelatedTask = <div className="non-related-task"> </div>;

      return rendererOfNonRelatedTask;
    }
    const rendererOfNonRelatedTask = rowObjects;

    return rendererOfNonRelatedTask;

  };

  return (
    <div>
      <div className="unknown-div">
      </div>
      <div className="div1">
        <table className="usa-table-borderless">
          <thead>
            <tr>
              <th className="style-for-tasks-and-content">Tasks</th>
              <th className="style-for-tasks-and-content">Task Instructions or Context</th>
            </tr>
          </thead>
          <tbody>
            {renderNonRelatedTask()}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default ConfirmTasksNotRelatedToAnAppeal;
