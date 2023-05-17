import React from 'react';
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

class QueueTableBuilder extends React.PureComponent {
  paginationOptions = () => querystring.parse(window.location.search.slice(1));

  calculateActiveTabIndex = (config) => {
    const tabNames = config.tabs.map((tab) => {
      return tab.name;
    });

    const activeTab = this.paginationOptions().tab || config.active_tab;
    const index = _.indexOf(tabNames, activeTab);

    return index === -1 ? 0 : index;
  };

  queueConfig = () => {
    const { config } = this.props;

    config.active_tab_index = this.calculateActiveTabIndex(config);

    return config;
  };

  filterValuesForColumn = (column) =>
    column && column.filterable && column.filter_options;

  createColumnObject = (column, config, tasks) => {

    const { requireDasRecord } = this.props;
    const filterOptions = this.filterValuesForColumn(column);
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

  columnsFromConfig = (config, tabConfig, tasks) =>
    (tabConfig.columns || []).map((column) =>
      this.createColumnObject(column, config, tasks)
    );

  // onHistoryUpdate = (path) => {
  //   console.log('setting history to');
  //   console.log(path);
  // };

  // TODO: Don't think this is going to work for queue unfortunately
  onHistoryUpdate = (urlString) => {
    const url = new URL(urlString);
    const params = new URLSearchParams(url.search);
    const filterParams = params.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);

    console.log('in onhistoryupdate in queuetablebuilder');
    // console.log('setting filter param here I guess?');
    // console.log(filterParams);

    // localStorage.setItem('queueFilter', filterParams);

    // setFilter(filterParam);
  };

  taskTableTabFactory = (tabConfig, config) => {
    const paginationOptions = this.paginationOptions();
    const tasks = tasksWithAppealsFromRawTasks(tabConfig.tasks);
    let totalTaskCount = tabConfig.total_task_count;
    let noCasesMessage;

    if (tabConfig.contains_legacy_tasks) {
      tasks.unshift(...this.props.assignedTasks);
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
    if (!paginationOptions?.sort_by) {
      Object.assign(defaultSort, tabConfig.defaultSort);
    }

    // TODO: I don't want to do this here as well
    // const params = new URLSearchParams(window.location.search);
    // const filterParams = params.getAll(`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`);
    // const localQueueFilter = localStorage.getItem('queueFilter');
    // const filter = filterParams.length > 0 ? filterParams : localQueueFilter;

    console.log('my filter in queue table builder');
    // console.log(filterParams);
    // console.log(filter);

    // TODO: Pulled from how NonComp works. I don't want to do this at all but I might not have a choice
    // TODO: It doesn't work anyhow because of how filters are preserved between tabs since this is never called more than one time.
    // I might have to do it down in QueueTable.jsx which sucks really hard.
    // paginationOptions[`${QUEUE_CONFIG.FILTER_COLUMN_REQUEST_PARAM}[]`] = filter;

    return {
      label: sprintf(tabConfig.label, totalTaskCount),
      page: (
        <React.Fragment>
          <p className="cf-margin-top-0">
            {noCasesMessage || tabConfig.description}
          </p>
          {this.props.userCanBulkAssign && tabConfig.allow_bulk_assign && (
            <BulkAssignButton />
          )}
          <QueueTable
            key={tabConfig.name}
            columns={this.columnsFromConfig(config, tabConfig, tasks)}
            rowObjects={tasks}
            getKeyForRow={(_rowNumber, task) => task.uniqueId}
            casesPerPage={config.tasks_per_page}
            numberOfPages={tabConfig.task_page_count}
            totalTaskCount={totalTaskCount}
            taskPagesApiEndpoint={tabConfig.task_page_endpoint_base_path}
            tabPaginationOptions={
              paginationOptions.tab === tabConfig.name && paginationOptions
            }
            onHistoryUpdate={this.onHistoryUpdate}
            preserveFilter
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

  tabsFromConfig = (config) =>
    (config.tabs || []).map((tabConfig) =>
      this.taskTableTabFactory(tabConfig, config)
    );

  render = () => {
    const config = this.queueConfig();

    return (
      <div className={rootStyles}>
        <h1 {...css({ display: 'inline-block' })}>{config.table_title}</h1>
        <QueueOrganizationDropdown organizations={this.props.organizations} />
        <TabWindow
          name="tasks-tabwindow"
          tabs={this.tabsFromConfig(config)}
          defaultPage={config.active_tab_index}
        />
      </div>
    );
  };
}

const mapStateToProps = (state) => {
  return {
    config: state.queue.queueConfig,
    organizations: state.ui.organizations,
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
};

export default connect(mapStateToProps)(QueueTableBuilder);
