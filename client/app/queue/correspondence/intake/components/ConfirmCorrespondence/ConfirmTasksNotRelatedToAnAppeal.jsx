import React from 'react';
import { useSelector } from 'react-redux';
import { COLORS } from '../../../../../constants/AppConstants';
import { css } from 'glamor';

const styling = { backgroundColor: COLORS.GREY_BACKGROUND, paddingTop: '0px' };

const ConfirmTasksNotRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);

  const rowObjects = tasks.map((task) => {
    return (
      <tr key={task.id}>
        <td
          style={{ backgroundColor: COLORS.GREY_BACKGROUND, borderTop: '1px solid #dee2e6', width: '20%' }}>
          {task.label}
        </td>
        <td style={{ backgroundColor: COLORS.GREY_BACKGROUND, borderTop: '1px solid #dee2e6' }}>
          {task.content}
        </td>
      </tr>
    );
  });

  const renderNonRelatedTask = () => {
    if (tasks.length === 0) {
      const rendererOfNonRelatedTask = <div {...css({
        marginBottom: '150px',
        paddingTop: '10px',
        fontWeight: 'bold'
      })}> </div>;

      return rendererOfNonRelatedTask;
    }
    const rendererOfNonRelatedTask = rowObjects;

    return rendererOfNonRelatedTask;

  };

  return (
    <div>
      <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
      </div>
      <div
        style={{ background: COLORS.GREY_BACKGROUND,
          padding: '2rem',
          paddingTop: '.1rem',
          paddingLeft: '20px',
          paddingRight: '20px' }}>
        <table className="usa-table-borderless">
          <thead>
            <tr>
              <th style={styling}>Tasks</th>
              <th style={styling}>Task Instructions or Context</th>
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
