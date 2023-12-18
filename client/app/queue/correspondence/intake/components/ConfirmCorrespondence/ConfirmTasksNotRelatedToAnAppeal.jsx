import React from 'react';
import { useSelector } from 'react-redux';

const styling = { backgroundColor: '#f5f5f5' };

const ConfirmTasksNotRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);

  const rowObjects = tasks.map((task) => {
    return (
      <tr key={task.id}>
        <td
          style={{ backgroundColor: '#f5f5f5', borderTop: '1px solid #dee2e6', width: '20%' }}>
          {task.label}
        </td>
        <td style={{ backgroundColor: '#f5f5f5', borderTop: '1px solid #dee2e6' }}>
          {task.content}
        </td>
      </tr>
    );
  });

  return (
    <div>
      <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
      </div>
      <div
        style={{ background: '#f5f5f5', padding: '2rem', paddingTop: '0.5rem', marginBottom: '2rem' }}>
        <table className="usa-table-borderless">
          <thead>
            <tr>
              <th style={styling}>Tasks</th>
              <th style={styling}>Task Instructions or Context</th>
            </tr>
          </thead>
          <tbody>
            {rowObjects}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default ConfirmTasksNotRelatedToAnAppeal;
