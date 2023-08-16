import React, { useState, useEffect } from 'react';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';
import querystring from 'querystring';

import BulkAssignButton from './components/BulkAssignButton';
import QueueTable from './QueueTable';
import TabWindow from '../components/TabWindow';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
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
import { tasksWithAppealsFromRawTasks } from './utils';

import COPY from '../../COPY';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';
import { css } from 'glamor';
import { isActiveOrganizationVHA } from '../queue/selectors';

const rootStyles = css({
  '.usa-alert + &': {
    marginTop: '1.5em'
  }
});

/**
 * A component to create a queue table's tabs and columns from a queue config or the assignee's tasks
 * The props are:
 * - @assignedTasks {array[object]} array of task objects to appear in the assigned tab
 **/

const QueueTableBuilder = (props) => {
  const paginationOptions = () => querystring.parse(window.location.search.slice(1));
  const [storedPaginationOptions, setStoredPaginationOptions] = useState(
    querystring.parse(window.location.search.slice(1))
  );

  // Causes one additional rerender of the QueueTables/tabs but prevents saved pagination behavior
  // e.g. clearing filter in a tab, then swapping tabs, then swapping back and the filter will still be applied
  useEffect(() => {
    setStoredPaginationOptions({});
  }, []);

  const calculateActiveTabIndex = (config) => {
    const tabNames = config.tabs.map((tab) => {
      return tab.name;
    });

    const activeTab = paginationOptions().tab || config.active_tab;
    const index = _.indexOf(tabNames, activeTab);

    return index === -1 ? 0 : index;
  };

  const queueConfig = () => {
    const { config } = props;

    config.active_tab_index = calculateActiveTabIndex(config);

    return config;
  };

  const filterValuesForColumn = (column) =>
    column && column.filterable && column.filter_options;

  const createColumnObject = (column, config, tasks) => {

    const { requireDasRecord } = props;
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

  const columnsFromConfig = (config, tabConfig, tasks) =>
    (tabConfig.columns || []).map((column) =>
      createColumnObject(column, config, tasks)
    );

  const taskTableTabFactory = (tabConfig, config) => {
    const savedPaginationOptions = storedPaginationOptions;
    const tasks = tasksWithAppealsFromRawTasks(tabConfig.tasks);
    let totalTaskCount = tabConfig.total_task_count;
    let noCasesMessage;

    const { isVhaOrg } = props;

    if (tabConfig.contains_legacy_tasks) {
      if (tasks) {
        props.assignedTasks.forEach((assignedTask) => {
          const i = tasks.findIndex((task) => task.externalAppealId === assignedTask.uniqueId);

          if (i <= -1) {
            tasks.unshift(assignedTask);
          }
        });
      } else {
        tasks.unshift(...props.assignedTasks);
      }


      totalTaskCount = tasks.length;

      noCasesMessage = totalTaskCount === 0 && (
        <p>
          {COPY.NO_CASES_IN_QUEUE_MESSAGE}
          <b>
            <Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link>
          </b>
          .
        </p>
      );
    }

    // Setup default sorting.
    const defaultSort = {};

    // If there is no sort by column in the pagination options, then use the tab config default sort
    // eslint-disable-next-line camelcase
    if (!savedPaginationOptions?.sort_by) {
      Object.assign(defaultSort, tabConfig.defaultSort);
    }

    return {
      label: sprintf(tabConfig.label, totalTaskCount),
      page: (
        <React.Fragment>
          <p className="cf-margin-top-0">
            {noCasesMessage || tabConfig.description}
          </p>
          {props.userCanBulkAssign && tabConfig.allow_bulk_assign && (
            <BulkAssignButton />
          )}
          <QueueTable
            key={tabConfig.name}
            columns={columnsFromConfig(config, tabConfig, tasks)}
            rowObjects={tasks}
            getKeyForRow={(_rowNumber, task) => task.uniqueId}
            casesPerPage={config.tasks_per_page}
            numberOfPages={tabConfig.task_page_count}
            totalTaskCount={totalTaskCount}
            taskPagesApiEndpoint={tabConfig.task_page_endpoint_base_path}
            tabPaginationOptions={
              savedPaginationOptions.tab === tabConfig.name && savedPaginationOptions
            }
            // Limit filter preservation/retention to only VHA orgs for now.
            {...(isVhaOrg ? { preserveFilter: true } : {})}
            defaultSort={defaultSort}
            useTaskPagesApi={
              config.use_task_pages_api && !tabConfig.contains_legacy_tasks
            }
            enablePagination
          />
        </React.Fragment>
      ),
    };
  };

  const tabsFromConfig = (config) =>
    (config.tabs || []).map((tabConfig) =>
      taskTableTabFactory(tabConfig, config)
    );

  const config = queueConfig();

  return <div className={rootStyles}>
    <h1 {...css({ display: 'inline-block' })}>{config.table_title}</h1>
    <QueueOrganizationDropdown organizations={props.organizations} />
    <TabWindow
      name="tasks-tabwindow"
      tabs={tabsFromConfig(config)}
      defaultPage={config.active_tab_index}
    />
  </div>;
};

const mapStateToProps = (state) => {
  return {
    config: state.queue.queueConfig,
    organizations: state.ui.organizations,
    isVhaOrg: isActiveOrganizationVHA(state),
    userCanBulkAssign: state.ui.activeOrganization.userCanBulkAssign,
  };
};

QueueTableBuilder.propTypes = {
  organizations: PropTypes.array,
  assignedTasks: PropTypes.array,
  config: PropTypes.shape({
    table_title: PropTypes.string,
    active_tab_index: PropTypes.number,
  }),
  requireDasRecord: PropTypes.bool,
  userCanBulkAssign: PropTypes.bool,
  isVhaOrg: PropTypes.bool,
};

export default connect(mapStateToProps)(QueueTableBuilder);
