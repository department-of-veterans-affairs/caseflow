import React from 'react';
import PropTypes from 'prop-types';
import QueueTable from 'app/queue/QueueTable';
import Button from 'app/components/Button';

export const ListTable = ({ user, history, hearingScheduleColumns, hearingScheduleRows, onQueryUpdate, fetching }) => {
  console.log('COLUMNS: ', hearingScheduleColumns);
  console.log('ROWS: ', hearingScheduleRows);

  return (
    <React.Fragment>
      {user.userCanBuildHearingSchedule && (
        <div style={{ marginBottom: 25 }}>
          <Button linkStyling onClick={() => history.push('/schedule/add_hearing_day')}>
          Add Hearing Day
          </Button>
        </div>
      )}
      <QueueTable
        fetching={fetching}
        columns={hearingScheduleColumns}
        rowObjects={hearingScheduleRows}
        returnQueries={onQueryUpdate}
        summary="hearing-schedule"
        slowReRendersAreOk
        useHearingsApi
      />
    </React.Fragment>
  );
};

ListTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  history: PropTypes.object,
  onQueryUpdate: PropTypes.func,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};
