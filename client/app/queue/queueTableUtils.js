import {
  assignedToColumn,
  assignedByColumn,
  badgesColumn,
  boardIntakeColumn,
  completedToNameColumn,
  daysOnHoldColumn,
  daysSinceLastActionColumn,
  daysSinceIntakeColumn,
  receiptDateColumn,
  daysWaitingColumn,
  detailsColumn,
  docketNumberColumn,
  documentIdColumn,
  lastActionColumn,
  issueCountColumn,
  issueTypesColumn,
  readerLinkColumn,
  readerLinkColumnWithNewDocsIcon,
  regionalOfficeColumn,
  taskColumn,
  taskOwnerColumn,
  taskCompletedDateColumn,
  typeColumn,
  vamcOwnerColumn
} from './components/TaskTableColumns';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';

const filterValuesForColumn = (column) =>
  column && column.filterable && column.filter_options;

export const createColumnObject = (column, config, tasks, requireDasRecord) => {

  const filterOptions = filterValuesForColumn(column);
  const functionForColumn = {
    [QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]: typeColumn(
      tasks,
      filterOptions,
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.BADGES.name]: badgesColumn(tasks),
    [QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]: detailsColumn(
      tasks,
      requireDasRecord,
      config.userRole
    ),
    [QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]: daysOnHoldColumn(
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.DAYS_SINCE_LAST_ACTION.name]: daysSinceLastActionColumn(
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]: daysWaitingColumn(
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(
      tasks,
      filterOptions,
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name]: readerLinkColumn(
      requireDasRecord,
      true
    ),
    [QUEUE_CONFIG.COLUMNS.DOCUMENT_ID.name]: documentIdColumn(),
    [QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]: issueCountColumn(
      tasks,
      filterOptions,
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name]: issueTypesColumn(
      tasks,
      filterOptions,
      requireDasRecord
    ),
    [QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.
      name]: readerLinkColumnWithNewDocsIcon(requireDasRecord),
    [QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name]: regionalOfficeColumn(
      tasks,
      filterOptions
    ),
    [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name]: assignedToColumn(
      tasks,
      filterOptions
    ),
    [QUEUE_CONFIG.COLUMNS.BOARD_INTAKE.name]: boardIntakeColumn(
      filterOptions
    ),
    [QUEUE_CONFIG.COLUMNS.LAST_ACTION.name]: lastActionColumn(
      tasks,
      filterOptions
    ),
    [QUEUE_CONFIG.COLUMNS.TASK_OWNER.name]: taskOwnerColumn(
      filterOptions
    ),
    [QUEUE_CONFIG.COLUMNS.VAMC_OWNER.name]: vamcOwnerColumn(
      tasks,
      filterOptions
    ),
    [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name]: completedToNameColumn(),
    [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name]: assignedByColumn(),
    [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
    [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, filterOptions),
    [QUEUE_CONFIG.COLUMNS.DAYS_SINCE_INTAKE.name]: daysSinceIntakeColumn(requireDasRecord),
    [QUEUE_CONFIG.COLUMNS.RECEIPT_DATE_INTAKE.name]: receiptDateColumn(),
  };

  return functionForColumn[column.name];
};

export const columnsFromConfig = (config, tabConfig, tasks) =>
  (tabConfig.columns || []).map((column) =>
    createColumnObject(column, config, tasks)
  );
