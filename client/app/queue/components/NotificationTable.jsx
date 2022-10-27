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

  const splitNotifications = (notifications) => {
    const tableNotifications = [];

    for (let i = 0; i < notifications.length; i++) {
      const notification = notifications[i];
      const type = notification.attributes.notification_type;

      if (type === 'Email and SMS') {
        tableNotifications.push(
          { ...notification, attributes: { ...notification.attributes, notification_type: 'Email' } },
          { ...notification, attributes: { ...notification.attributes, notification_type: 'SMS' } }
        );
      } else if (type === 'Email' || type === 'SMS') {
        tableNotifications.push(notification);
      }
    }

    return tableNotifications;
  };

  // Purpose: Send a request call to the backend endpoint for notifications
  const fetchNotifications = async () => {
    const url = `/appeals/${appealId}/notifications`;

    const data = await ApiUtil.get(url).
      then((response) => response.body).
      catch((response) => console.error(response));

    return data;
  };

  const updateNotificationList = async () => {
    const notifications = await fetchNotifications();
    const tableNotifications = splitNotifications(notifications);

    setNotificationList(tableNotifications);
  };

  // Do the fetch only once per load
  useEffect(() => {
    updateNotificationList();
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
      sortColName="Notification Date"
      defaultSort={{
        sortColName: 'notificationDateColumn',
        sortAscending: true
      }}
    />
  );
};

NotificationTable.propTypes = {
  appealId: PropTypes.string.isRequired,
};

export default NotificationTable;
