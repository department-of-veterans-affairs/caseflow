import React from 'react';
import QueueTable from '../QueueTable';
import { eventTypeColumn } from './NotificationTableColumns';
import { badgesColumn } from './TaskTableColumns';
import NOTIFICATION_CONFIG from '../../../constants/NOTIFICATION_CONFIG';
import { filter } from 'lodash';

const NotificationTable = () => {
  // Retrieves notification table columns
  const getNotificationColumns = () => {
    return [
      badgesColumn(),
      eventTypeColumn()
    ];
  };

  const createColumnObject = (column) => {
    const functionForColumn = { [NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn([]) };

    return functionForColumn[column.name];
  };

  const columnsFromConfig = (columns) => {
    const builtColumns = [];

    for (const column of Object.values(columns)) {
      builtColumns.push(createColumnObject(column));
    }

    return builtColumns;
  };

  return (
    <QueueTable
      columns={columnsFromConfig(NOTIFICATION_CONFIG.COLUMNS)}
      rowObjects={[]}
      enablePagination
      casesPerPage={15}
      numberofPages={1}
    />
  );
};

export default NotificationTable;
