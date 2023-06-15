/* eslint-disable camelcase */
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
import NotificationModal from './NotificationModal';

const NotificationTable = ({ appealId, modalState, openModal, closeModal }) => {

  const [notificationList, setNotificationList] = useState([]);

  const [notificationState, setNotificationState] = useState({});

  const handleNotification = (state) => {
    setNotificationState(state);
  };

  // Purpose: This function generates one or two entries for each record depending on notification type
  // Params: notifications - The notification list recieved from get request call
  // Return: The generated table entries
  const generateTableEntries = (notifications) => {
    let notificationsArr = notifications;

    if (!notifications) {
      notificationsArr = [];
    }
    const tableNotifications = [];

    for (let i = 0; i < notificationsArr.length; i++) {
      const {
        email_notification_status,
        sms_notification_status,
        notification_content,
        sms_notification_content,
        notification_type,
        recipient_email,
        recipient_phone_number,
        event_type,
        event_date,
      } = notifications[i];

      const email_notification = {
        status: email_notification_status === 'Success' ? 'Sent' : email_notification_status,
        content: notification_content,
        notification_type: 'Email',
        // eslint-disable-next-line no-negated-condition
        recipient_information: recipient_email === '' ? null : recipient_email,
        event_type,
        event_date
      };

      const sms_notification = {
        status: sms_notification_status === 'Success' ? 'Sent' : sms_notification_status,
        content: sms_notification_content,
        notification_type: 'Text',
        // eslint-disable-next-line no-negated-condition
        recipient_information: recipient_phone_number === '' ? null : recipient_phone_number,
        event_type,
        event_date
      };

      if (notification_type === 'Email and SMS') {
        tableNotifications.push(email_notification, sms_notification);
      } else if (notification_type === 'Email') {
        tableNotifications.push(email_notification);
      } else if (notification_type === 'SMS') {
        tableNotifications.push(sms_notification);
      }
    }

    return tableNotifications;
  };

  // Purpose: Send a request call to the backend endpoint for notifications
  // Params: id - uuis or vacols id of an AMA appeal or Legacy Appeal
  // Return: The fetched data from the endpoint
  const fetchNotifications = async (id) => {
    const url = `/appeals/${id}/notifications`;

    const data = await ApiUtil.get(url).
      then((response) => response.body).
      catch((response) => console.error(response));

    return data;
  };

  // Purpose: It will update the notificationList state with the new entries that have been generated
  const updateNotificationList = async () => {
    const notifications = await fetchNotifications(appealId);
    const tableNotifications = generateTableEntries(notifications);

    setNotificationList(tableNotifications);
  };

  // Do the fetch only once per load
  useEffect(() => {
    updateNotificationList();
  }, []);

  // Purpose: This is a mapping for the column types and the functions it will use to generate the column and row data
  // Params: column - A column type
  // Return: The generated column
  const createColumnObject = (column) => {
    const functionForColumn = {
      // eslint-disable-next-line max-len
      [NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(notificationList, modalState, openModal, handleNotification),
      [NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.name]: notificationDateColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.name]: notificationTypeColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.name]: recipientInformationColumn(notificationList),
      [NOTIFICATION_CONFIG.COLUMNS.STATUS.name]: statusColumn(notificationList)
    };

    return functionForColumn[column.name];
  };

  // Purpose: This will generate the columns
  // Params: columns - All of the columns that will be used for the table
  // Return: The generated columns
  const columnsFromConfig = (columns) => {
    const builtColumns = [];

    for (const column of Object.values(columns)) {
      builtColumns.push(createColumnObject(column));
    }

    return builtColumns;
  };

  return (
    <>
      <QueueTable
        columns={columnsFromConfig(NOTIFICATION_CONFIG.COLUMNS)}
        rowObjects={notificationList}
        enablePagination
        casesPerPage={15}
        sortColName="Notification Date"
        defaultSort={{
          sortColName: 'notificationDateColumn',
          sortAscending: true
        }}
      />
      {modalState &&
      <NotificationModal
        eventType={notificationState.event_type}
        notificationContent={notificationState.content}
        closeNotificationModal={closeModal}
      />}
    </>
  );
};

NotificationTable.propTypes = {
  appealId: PropTypes.string.isRequired,
  modalState: PropTypes.bool,
  openModal: PropTypes.func,
  closeModal: PropTypes.func
};

export default NotificationTable;
