import React, { useState, useEffect } from 'react';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';
import querystring from 'querystring';

import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';
import QueueTable from '../QueueTable';
import TabWindow from '../../components/TabWindow';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';
import {
  actionType,
  assignedToColumn,
  assignedByColumn,
  checkboxColumn,
  daysWaitingCorrespondence,
  notes,
  taskColumn,
  taskCompletedDateColumn,
  vaDor,
  veteranDetails
} from '../components/TaskTableColumns';
import { tasksWithCorrespondenceFromRawTasks } from '../utils';

import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import { css } from 'glamor';
import { isActiveOrganizationVHA } from '../selectors';

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

const CorrespondenceTableBuilder = (props) => {
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

    const filterOptions = filterValuesForColumn(column);
    const functionForColumn = {
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name]: daysWaitingCorrespondence(),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name]: assignedToColumn(
        tasks,
        filterOptions
      ),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name]: assignedByColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name]: veteranDetails(),
      [QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name]: vaDor(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.NOTES.name]: notes(),
      [QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name]: checkboxColumn(),
      [QUEUE_CONFIG.COLUMNS.ACTION_TYPE.name]: actionType(),
    };

    return functionForColumn[column.name];
  };

  const columnsFromConfig = (config, tabConfig, tasks) =>
    (tabConfig.columns || []).map((column) =>
      createColumnObject(column, config, tasks)
    );

  const taskTableTabFactory = (tabConfig, config) => {
    const savedPaginationOptions = storedPaginationOptions;
    const tasks = tasksWithCorrespondenceFromRawTasks(tabConfig.tasks);
    let totalTaskCount = tabConfig.total_task_count;
    let noCasesMessage;

    const { isVhaOrg } = props;

    if (tabConfig.contains_legacy_tasks) {
      tasks.unshift(...props.assignedTasks);
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
        <>
          {(tabConfig.name === 'correspondence_unassigned' || tabConfig.name === 'correspondence_team_assigned') &&
            <>
              <p className="cf-margin-bottom-0rem">Assign to mail team user</p>
              <div style={{ display: 'flex', flexDirection: 'row' }}>
                <SearchableDropdown
                  className="cf-dropdown"
                  name="Assign to mail team user"
                  hideLabel
                  styling={{ width: '200px', marginRight: '2rem' }}
                  dropdownStyling={{ width: '200px' }}
                />
                {tabConfig.name === 'correspondence_unassigned' &&
              <>
                <Button
                  name="Assign"
                />
                <span style={{ marginLeft: 'auto' }}>
                  <Button
                    name="Auto assign correspondence"
                  />
                </span>
              </>
                }
                {tabConfig.name === 'correspondence_team_assigned' &&
            <Button
              name="Reassign"
            />
                }
              </div>
              <hr></hr>
            </>
          }
          <p className="cf-margin-top-0">
            {noCasesMessage || tabConfig.description}
          </p>
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
              savedPaginationOptions.tab === tabConfig.name ? savedPaginationOptions : {}
            }
            // Limit filter preservation/retention to only VHA orgs for now.
            {...(isVhaOrg ? { preserveFilter: true } : {})}
            defaultSort={defaultSort}
            useTaskPagesApi={
              config.use_task_pages_api && !tabConfig.contains_legacy_tasks
            }
            enablePagination
            isCorrespondenceTable
          />
        </>
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
    <QueueOrganizationDropdown organizations={props.organizations} featureToggles = {props.featureToggles} />
    <TabWindow
      name="tasks-tabwindow"
      tabs={tabsFromConfig(config)}
      defaultPage={config.active_tab_index}
    />
  </div>;
};

const mapStateToProps = (state) => {
  return {
    config: state.intakeCorrespondence.correspondenceConfig,
    organizations: state.ui.organizations,
    isVhaOrg: isActiveOrganizationVHA(state),
    userCanBulkAssign: state.ui.activeOrganization.userCanBulkAssign,
  };
};

CorrespondenceTableBuilder.propTypes = {
  organizations: PropTypes.array,
  assignedTasks: PropTypes.array,
  config: PropTypes.shape({
    table_title: PropTypes.string,
    active_tab_index: PropTypes.number,
  }),
  userCanBulkAssign: PropTypes.bool,
  isVhaOrg: PropTypes.bool,
  featureToggles: PropTypes.object
};

export default connect(mapStateToProps)(CorrespondenceTableBuilder);
