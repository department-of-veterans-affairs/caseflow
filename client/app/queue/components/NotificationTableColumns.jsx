import COPY from '../../../COPY';
import NOTIFICATION_CONFIG from '../../../constants/NOTIFICATION_CONFIG';
import EVENT_TYPE_FILTERS from '../../../constants/EVENT_TYPE_FILTERS';

export const eventTypeColumn = (notifications) => {
  const filterOptions = Object.values(EVENT_TYPE_FILTERS);

  return {
    header: COPY.NOTIFICATION_EVENT_TYPE_COLUMN_NAME,
    name: NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.filterable,
    customFilterLabels: EVENT_TYPE_FILTERS,
    columnName: 'Event',
    tableData: notifications,
    filterOptions,
    label: "Filter by event type",
    valueName: "Event",
    valueFunction: (notification) => notification.event_type
  };
};

export const notificationDateColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_DATE_COLUMN_NAME,
    name: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.filterable,
    columnName: 'notification.date',
    tableData: notifications,
    valueName: "Date",
    valueFunction: (notification) => notification.event_date,
    getSortValue: (notification) => notification.event_date
  };
};

export const notificationTypeColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_TYPE_COLUMN_NAME,
    name: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.filterable,
    columnName: 'notification.type',
    tableData: notifications,
    valueName: "Type",
    valueFunction: (notification) => notification.notification_type
  };
};

export const recipientInformationColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_RECIPIENT_INFORMATION,
    name: NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.filterable,
    columnName: 'notification.recipient_information',
    tableData: notifications,
    valueName: "Recipient Info",
    valueFunction: (notification) => notification.recipient_email
  };
};

export const statusColumn = (notifications) => {
  return {
    header: COPY.NOTIFICATION_STATUS,
    name: NOTIFICATION_CONFIG.COLUMNS.STATUS.name,
    enableFilter: NOTIFICATION_CONFIG.COLUMNS.STATUS.filterable,
    columnName: 'notification.status',
    tableData: notifications,
    valueName: 'Status',
    valueFunction: (notification) => {
      const email = notification.email_notification_status;

      return email.charAt(0).toUpperCase() + email.slice(1);
    }
  };
};
