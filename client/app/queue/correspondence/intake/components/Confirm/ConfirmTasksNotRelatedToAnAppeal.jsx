import React from 'react';
import { useSelector } from 'react-redux';
import { ICON_SIZES, COLORS } from 'app/constants/AppConstants';
import { PencilIcon } from 'app/components/icons/PencilIcon';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Button from 'app/components/Button';
import { css } from 'glamor';

const styling = { backgroundColor: COLORS.GREY_BACKGROUND };

const ConfirmTasksNotRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);

  const handleClickEdit = () => {
    console.log(1);
  };

  const rowObjects = tasks.map((task) => {
    return (
      <tr>
        <td style={{ backgroundColor: COLORS.GREY_BACKGROUND, borderTop: '1px solid #dee2e6', width: '20%' }}>
          {task.type}
        </td>
        <td style={{ backgroundColor: COLORS.GREY_BACKGROUND, borderTop: '1px solid #dee2e6' }}>
          {task.content}
        </td>
      </tr>
    );
  });

  return (
    <div>
      <div style={{ position: 'relative', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
        <h2 style={{ display: 'inline', marginBottom: '2rem' }}>Tasks not related to an Appeal</h2>
        <a
          onClick={handleClickEdit}
          href="#">
          <span style={{ position: 'absolute' }}><PencilIcon size={25} /></span>
          <span {...css({ marginLeft: '24px' })}>Edit section</span>
        </a>
      </div>
      <div
        style={{ background: COLORS.GREY_BACKGROUND, padding: '2rem', marginBottom: '2rem' }}>
        <table className="usa-table-borderless">
          <thead>
            <th style={styling}>Tasks</th>
            <th style={styling}>Task Instructions or Context</th>
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
