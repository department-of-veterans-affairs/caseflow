import React from 'react';
import PropTypes from 'prop-types';
import QueueTable from 'app/queue/QueueTable';

export const ListTable = ({ hearingScheduleColumns, hearingScheduleRows, onQueryUpdate, fetching }) => (
  <QueueTable
    fetching={fetching}
    columns={hearingScheduleColumns}
    rowObjects={hearingScheduleRows}
    returnQueries={onQueryUpdate}
    summary="hearing-schedule"
    slowReRendersAreOk
    useHearingsApi
  />
);

ListTable.propTypes = {
  hearingScheduleColumns: PropTypes.array,
  hearingScheduleRows: PropTypes.array,
  history: PropTypes.object,
  onQueryUpdate: PropTypes.func,
  user: PropTypes.shape({
    userCanBuildHearingSchedule: PropTypes.bool
  })
};
