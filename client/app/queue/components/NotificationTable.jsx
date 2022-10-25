import React from 'react';
import QueueTable from '../QueueTable';
import { eventTypeColumn, notificationDateColumn, notificationTypeColumn, recipientInformationColumn, statusColumn } from './NotificationTableColumns';
import NOTIFICATION_CONFIG from '../../../constants/NOTIFICATION_CONFIG';

const NotificationTable = () => {
  const data = [{
        "id" : 24,
        "appeals_id" : "601560025",
        "appeals_type" : "LegacyAppeal",
        "created_at" : "2022-10-19T19:07:57.179Z",
        "email_enabled" : true,
        "email_notification_external_id" : null,
        "email_notification_status" : 'sent',
        "event_date" : "2022-10-19",
        "event_type" : "Appeal docketed",
        "notification_content" : null,
        "notification_type" : "Email and SMS",
        "notified_at" : null,
        "participant_id" : "500000123",
        "recipient_email" : "test@caseflow.com",
        "recipient_phone_number" : null,
        "sms_notification_external_id" : null,
        "sms_notification_status" : null,
        "updated_at" : "2022-10-19T19:07:57.179Z"
      },
      {
        "id" : 25,
        "appeals_id" : "601620353",
        "appeals_type" : "LegacyAppeal",
        "created_at" : "2022-10-19T19:07:58.267Z",
        "email_enabled" : true,
        "email_notification_external_id" : null,
        "email_notification_status" : 'sent',
        "event_date" : "2022-10-20",
        "event_type" : "Hearing scheduled",
        "notification_content" : null,
        "notification_type" : "Email and SMS",
        "notified_at" : null,
        "participant_id" : null,
        "recipient_email" : "vanotify@caseflow.com",
        "recipient_phone_number" : null,
        "sms_notification_external_id" : null,
        "sms_notification_status" : null,
        "updated_at" : "2022-10-19T19:07:58.267Z"
      }
    ]
  const createColumnObject = (column) => {
    const functionForColumn = {
      [NOTIFICATION_CONFIG.COLUMNS.EVENT_TYPE.name]: eventTypeColumn(data),
      [NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_DATE.name]: notificationDateColumn(data),
      [NOTIFICATION_CONFIG.COLUMNS.NOTIFICATION_TYPE.name]: notificationTypeColumn(data),
      [NOTIFICATION_CONFIG.COLUMNS.RECIPIENT_INFORMATION.name]: recipientInformationColumn(data),
      [NOTIFICATION_CONFIG.COLUMNS.STATUS.name]: statusColumn(data)
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
      rowObjects={data}
      enablePagination
      casesPerPage={15}
      numberofPages={1}
    />
  );
};

export default NotificationTable;
