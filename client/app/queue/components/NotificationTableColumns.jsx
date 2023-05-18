import React from 'react';
import COPY from '../../../COPY';
import NOTIFICATION_CONFIG from '../../../constants/NOTIFICATION_CONFIG';
import EVENT_TYPE_FILTERS from '../../../constants/EVENT_TYPE_FILTERS';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

// Purpose: These are all column objects for the notifications table
// Params: notifications - The list of notifications

// Styling for the event type column values
const eventTypeStyling = { fontWeight: 'bold', cursor: 'pointer' };

export const eventTypeColumn = (notifications, modalState, openModal, handleNotification) => {

  return {
    header: COPY.NOTIFICATION_EVENT_TYPE_COLUMN_NAME,
    name: NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.filterable,
    customFilterLabels: EVENT_TYPE_FILTERS,
    columnName: 'event_type',
    tableData: notifications,
    anyFiltersAreSet: true,
    label: 'Filter by event type',
    valueName: 'Event',
    valueFunction: (notification) =>
      <span>
        <span style={eventTypeStyling}>
          <Link onClick={() => {
            openModal();
            handleNotification(notification);
          }}
          >
            {notification.event_type}
          </Link>
        </span>
      </span>
  };
};

export const notificationDateColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_DATE_COLUMN_NAME,
    name: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.filterable,
    columnName: 'event_date',
    tableData: notifications,
    valueName: 'Notification Date',
    valueFunction: (notification) => {
      const dateArr = notification.event_date.split('-');

      dateArr.push(dateArr.shift());

      return dateArr.join('/');
    },
    getSortValue: (notification) => notification.event_date
  };
};

export const notificationTypeColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_TYPE_COLUMN_NAME,
    name: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.filterable,
    anyFiltersAreSet: true,
    label: 'Filter by notification type',
    columnName: 'notification_type',
    tableData: notifications,
    valueName: 'Notification Type',
    valueFunction: (notification) => notification.notification_type
  };
};

export const recipientInformationColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_RECIPIENT_INFORMATION,
    name: NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.filterable,
    anyFiltersAreSet: true,
    label: 'Filter by recipient information column',
    columnName: 'recipient_information',
    tableData: notifications,
    valueName: 'Recipient Information',
    // eslint-disable-next-line no-negated-condition
    valueFunction: (notification) => notification.status !== 'delivered' ? '—' : notification.recipient_information
  };
};

export const statusColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_STATUS,
    name: NOTIFICATION_CONFIG.COLUMNS.STATUS.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.STATUS.filterable,
    anyFiltersAreSet: true,
    label: 'Filter by status column',
    columnName: 'status',
    tableData: notifications,
    valueName: 'Status',
    valueFunction: (notification) => {
      const { status } = notification;

      return NOTIFICATION_CONFIG.STATUSES[status.toUpperCase()] || status.charAt(0).toUpperCase() + status.slice(1);
    }
  };
};

