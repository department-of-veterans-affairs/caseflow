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
    filterOptions,
    tableData: notifications,
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
    customFilterLabels: EVENT_TYPE_FILTERS,
    columnName: 'notification.date',
    tableData: notifications,
    getSortValue: (notification) => notification.event_date,
    valueFunction: (notification) => notification.event_date
  };
}
