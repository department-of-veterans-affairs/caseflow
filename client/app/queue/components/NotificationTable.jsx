import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import QueueTable from '../QueueTable';
import {
  eventTypeColumn,
  notificationDateColumn,
  notificationTypeColumn,
  recipientInformationColumn,
  statusColumn } from './NotificationTableColumns';
import NOTIFICATION_CONFIG from '../../../constants/NOTIFICATION_CONFIG';
import ApiUtil from '../../util/ApiUtil';

const NotificationTable = ({ appealId }) => {

  const [notificationList, setNotificationList] = useState([]);

  const fetchNotifications = () => {
    const url = `/appeals/${appealId}/notifications`;

    ApiUtil.get(url).
      then((response) => {
        const { notifications } = response.body;

        setNotificationList(notifications.data);
      }).
      catch((response) => {
        console.error(response);
        setNotificationList([]);
      });
  };

  useEffect(() => {
    fetchNotifications();
  }, []);

  const createColumnObject = (column) => {
    const functionForColumn = {
      [NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.name]: notificationDateColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.name]: notificationTypeColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.name]: recipientInformationColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.STATUS.name]: statusColumn(notificationList)
    };

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
      rowObjects={notificationList}
      enablePagination
      casesPerPage={15}
      numberofPages={1}
    />
  );
};

NotificationTable.propTypes = {
  appealId: PropTypes.string.isRequired,
};

export default NotificationTable;
