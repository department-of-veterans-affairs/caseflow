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
import Button from '../components/Button';
import {
  assignedToColumn,
  badgesColumn,
  completedToNameColumn,
  daysOnHoldColumn,
  daysWaitingColumn,
  detailsColumn,
  docketNumberColumn,
  documentIdColumn,
  issueCountColumn,
  readerLinkColumn,
  readerLinkColumnWithNewDocsIcon,
  regionalOfficeColumn,
  taskColumn,
  taskCompletedDateColumn,
  typeColumn,
  officeColumn
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

const style = css({
  float: 'right',
  margin: '10px'
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
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name]: completedToNameColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.OFFICE.name]: officeColumn(tasks, filterOptions),
    };

    return functionForColumn[column.name];
  };

  columnsFromConfig = (config, tabConfig, tasks) =>
    (tabConfig.columns || []).map((column) =>
      this.createColumnObject(column, config, tasks)
    );

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

    console.log(this.props);

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

  downloadCsv = () => {
//    location.href = ``; // Set to Download URL
  }

  newIntake = () => {
   location.href = `/intake`;
  }

  render = () => {
    const config = this.queueConfig();
    console.log("QTB Props", this.props)
    let header = <QueueOrganizationDropdown organizations={this.props.organizations} />;
    if (window.location.pathname.includes("vha-camo")) {
      const intakeButton = <Button {...style}
                              onClick={this.newIntake}>
                              + New Intake Form
                           </Button>;
      const downloadButton = <Button {...style}
                               classNames={['usa-button-secondary']}
                               onClick={this.downloadCsv}>
                               Download completed tasks
                             </Button>;
      header = <div {...style}>{intakeButton} {downloadButton}</div>
    }

    return (
      <div className={rootStyles}>
        <h1 {...css({ display: 'inline-block' })}>{config.table_title}</h1>
          {header}
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
