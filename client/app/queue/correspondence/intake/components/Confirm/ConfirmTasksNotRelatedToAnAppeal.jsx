import React from 'react';
import Table from 'app/components/Table';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { useSelector } from 'react-redux';
import { TitleDetailsSubheader } from 'app/components/TitleDetailsSubheader';
import { css } from 'glamor';
import { COLORS } from 'app/constants/AppConstants';
import TitleDetailsSubheaderSection from 'app/queue/correspondence/review_package/ReviewPackageData';


const ConfirmTasksNotRelatedToAnAppeal = () => {
  const tasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);

  const rowObjects = tasks.map((task) => {
    return (
      <tr>
        <td>
          {task.type}
        </td>
        <td>
          {task.content}
        </td>
      </tr>
    );
  });

  const columns = [
    {
      header: 'Tasks',
      valueName: 'tasks',
      align: 'left'
    },
    {
      header: 'Task Instructions or Context',
      valueName: 'taskInstructionsOrContext',
      align: 'left'
    }
  ];

  const styling = css({
    // backgroundColor: COLORS.GREY_BACKGROUND,
    border: '0px solid #000000'
  });

  return (
    <React.Fragment>
      <div>
        <table style={{ border: '0px solid #000000' }}>
          <thead>
            <th>Tasks</th>
            <th>Task Instructions or Context</th>
          </thead>
          <tbody>
            {rowObjects}
          </tbody>
        </table>
        {/* columns={columns}
        rowObjects={rowObjects}
        bodyClassName="cf-document-list-body"
        headerClassName="comments-table-header"
        slowReRendersAreOk */}
      </div>
    </React.Fragment>
  );
};

export default ConfirmTasksNotRelatedToAnAppeal;
