import React, { useState, useEffect } from 'react';
import { useSelector, connect } from 'react-redux';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import querystring from 'querystring';
import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';
import moment from 'moment';
import QueueTable from '../QueueTable';
import TabWindow from '../../components/TabWindow';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import QueueOrganizationDropdown from '../components/QueueOrganizationDropdown';
import SearchBar from '../../components/SearchBar';
import BatchAutoAssignButton from './component/BatchAutoAssignButton';
import {
  actionType,
  assignedToColumn,
  assignedByColumn,
  checkboxColumn,
  daysWaitingCorrespondence,
  notes,
  taskColumn,
  correspondenceCompletedDateColumn,
  vaDor,
  veteranDetails,
  packageDocumentType
} from '../components/TaskTableColumns';

import { tasksWithCorrespondenceFromRawTasks } from '../utils';

import COPY from '../../../COPY';
import QUEUE_CONFIG from '../../../constants/QUEUE_CONFIG';
import { isActiveOrganizationVHA } from '../selectors';

/**
 * A component to create a queue table's tabs and columns from a queue config or the assignee's tasks
 * The props are:
 * - @assignedTasks {array[object]} array of task objects to appear in the assigned tab
 **/

const buildMailUserData = (data) => {
  return data.map((user) => {
    return {
      value: user,
      label: user
    };
  });
};

const CorrespondenceTableBuilder = (props) => {
  const [selectedMailTeamUser, setSelectedMailTeamUser] = useState(null);
  const [isAnyCheckboxSelected, setIsAnyCheckboxSelected] = useState(false);
  const [isDropdownItemSelected, setIsDropdownItemSelected] = useState(false);
  const [searchValue, setSearchValue] = useState('');
  const selectedTasks = useSelector((state) => state.intakeCorrespondence.selectedTasks);

  const paginationOptions = () => querystring.parse(window.location.search.slice(1));
  const [storedPaginationOptions, setStoredPaginationOptions] = useState(
    querystring.parse(window.location.search.slice(1))
  );

  // Causes one additional rerender of the QueueTables/tabs but prevents saved pagination behavior
  // e.g. clearing filter in a tab, then swapping tabs, then swapping back and the filter will still be applied
  useEffect(() => {
    setStoredPaginationOptions({});
  }, []);

  const handleMailTeamUserChange = (selectedUser) => {
    setSelectedMailTeamUser(selectedUser);
    setIsDropdownItemSelected(Boolean(selectedUser));
  };

  const handleCheckboxChange = (isChecked) => {
    setIsAnyCheckboxSelected(isChecked);
  };

  const handleAssignButtonClick = () => {
    // Logic to handle assigning tasks to the selected mail team user
    // candidate for refactor using PATCH request
    if (selectedMailTeamUser && isDropdownItemSelected && isAnyCheckboxSelected) {
      const mailTeamUser = selectedMailTeamUser.value;
      const taskIds = selectedTasks.map((task) => task);
      let newUrl = window.location.href;

      newUrl += newUrl.includes('?') ? `&user=${mailTeamUser}&task_ids=${taskIds}` :
        `?user=${mailTeamUser}&task_ids=${taskIds}`;
      window.location.href = newUrl;
    }
  };

  const calcActiveTabIndex = (config) => {
    const tabNames = config.tabs.map((tab) => {
      return tab.name;
    });

    const activeTab = paginationOptions().tab || config.active_tab;
    const index = _.indexOf(tabNames, activeTab);

    return index === -1 ? 0 : index;
  };

  const handleSearchChange = (value) => {
    setSearchValue(value);
  };

  const handleClearSearch = () => {
    setSearchValue('');
  };

  const taskMatchesSearch = (task) => {
    const taskNotes = task.notes || '';
    const daysWaiting = task.daysWaiting ? task.daysWaiting.toString() : '';
    const assignedByfirstName = (task.assignedBy && task.assignedBy.firstName) || '';
    const assignedBylastName = (task.assignedBy && task.assignedBy.lastName) || '';
    const assignedToName = (task.assignedTo && task.assignedTo.name) || '';
    const taskVeteranDetails = task.veteranDetails || '';
    const taskLabel = task.label || '';
    const taskVaDor = task.vaDor || '';
    const closedAt = task.closedAt || '';
    const packageDocType = task.nod ? 'NOD' : 'Non-NOD';
    const searchValueTrimmed = searchValue.trim();
    const isNumericSearchValue = !isNaN(parseFloat(searchValueTrimmed)) && isFinite(searchValueTrimmed);

    return (
      taskVeteranDetails.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    taskNotes.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    moment(taskVaDor).format('MM/DD/YYYY').
      includes(searchValueTrimmed) ||
    assignedByfirstName.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    assignedBylastName.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    assignedToName.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    packageDocType.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    taskLabel.toLowerCase().includes(searchValueTrimmed.toLowerCase()) ||
    (isNumericSearchValue && daysWaiting.trim() === searchValueTrimmed) ||
    moment(closedAt).format('MM/DD/YYYY').
      includes(searchValue)
    );
  };

  const queueConfig = () => {
    const { config } = props;

    config.active_tab_index = calcActiveTabIndex(config);

    return config;
  };

  const filterValuesForColumn = (column) =>
    column && column.filterable && column.filter_options;

  const createColumnObject = (column, config, tasks) => {

    const filterOptions = filterValuesForColumn(column);
    const functionForColumn = {
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING_CORRESPONDENCE.name]: daysWaitingCorrespondence(),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name]: assignedToColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNED_BY.name]: assignedByColumn(),
      [QUEUE_CONFIG.COLUMNS.CORRESPONDENCE_TASK_CLOSED_DATE.name]: correspondenceCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name]: veteranDetails(),
      [QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name]: vaDor(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.NOTES.name]: notes(),
      [QUEUE_CONFIG.COLUMNS.CHECKBOX_COLUMN.name]: checkboxColumn(handleCheckboxChange),
      [QUEUE_CONFIG.COLUMNS.ACTION_TYPE.name]: actionType(),
      [QUEUE_CONFIG.COLUMNS.PACKAGE_DOCUMENT_TYPE.name]: packageDocumentType(filterOptions)
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

    const getBulkAssignArea = () => {
      return (<>
        <p className="correspondence-table-builder-margin">Assign to Inbound Ops Team user</p>
        <div className="correspondence-table-builder-searchable-dropdown-position">
          <div className= "correspondence-table-builder-searchable-dropdown-style">
            <SearchableDropdown
              name="Assign to Inbound Ops Team user"
              hideLabel
              options={buildMailUserData(props.inboundOpsTeamNonAdmin)}
              onChange={handleMailTeamUserChange}
            />
          </div>
          {tabConfig.name === QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_TAB_NAME &&
              <>
                <span className="correspondence-table-builder-searchable-button-position">
                  <Button
                    name="Assign"
                    onClick={handleAssignButtonClick}
                    disabled={!isDropdownItemSelected || !isAnyCheckboxSelected}
                  />
                </span>
                <span className="correspondence-table-builder-searchable-auto-assign-button-position">
                  <BatchAutoAssignButton />
                </span>
              </>
          }
          {tabConfig.name === QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_TAB_NAME &&
            <span className="correspondence-table-builder-searchable-button-position">
              <Button
                name="Reassign"
                onClick={handleAssignButtonClick}
                disabled={!isDropdownItemSelected || !isAnyCheckboxSelected}
              />
            </span>
          }
        </div>
        <hr style={{ marginBottom: '17px' }}></hr>
      </>);

    };

    // If there is no sort by column in the pagination options, then use the tab config default sort
    // eslint-disable-next-line camelcase
    if (!savedPaginationOptions?.sort_by) {
      Object.assign(defaultSort, tabConfig.defaultSort);
    }

    return {
      label: sprintf(tabConfig.label, totalTaskCount),
      page: (
        <>
          {/* this setup should prevent a double render of the bulk assign area if a
          user is a superuser and also a supervisor */}
          {(props.isInboundOpsSupervisor || (props.isInboundOpsSupervisor && props.isInboundOpsSuperuser)) &&
            (tabConfig.name === QUEUE_CONFIG.CORRESPONDENCE_UNASSIGNED_TASKS_TAB_NAME ||
              tabConfig.name === QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_TAB_NAME) &&
            <>
              {getBulkAssignArea()}
            </>
          }
          {
            (props.isInboundOpsSuperuser && !props.isInboundOpsSupervisor &&
              tabConfig.name === QUEUE_CONFIG.CORRESPONDENCE_TEAM_ASSIGNED_TASKS_TAB_NAME) &&
          <>
            {getBulkAssignArea()}
          </>

          }
          <div className="correspondence-table-builder-filter-bar-position">
            <p className="correspondence-table-builder-margin">
              {noCasesMessage || tabConfig.description}
            </p>
            <div className="cf-noncomp-search">
              <SearchBar
                id="searchBar"
                size="small"
                title="Filter table by any of its columns"
                isSearchAhead
                placeholder="Type to filter..."
                onChange={(value) => handleSearchChange(value)}
                onClearSearch={handleClearSearch}
                value={searchValue}
              />
            </div>
          </div>

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
            searchValue={searchValue}
            taskMatchesSearch={taskMatchesSearch}
          />
        </>
      ),
    };
  };

  const tabsFromConfig = (config) => {
    return (config.tabs || []).map((tabConfig) =>
      taskTableTabFactory(tabConfig, config)
    );
  };

  const config = queueConfig();

  return <div>
    <h1 className="correspondence-table-builder-title">{config.table_title}</h1>
    <QueueOrganizationDropdown
      organizations={props.organizations}
    />
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
  featureToggles: PropTypes.object,
  inboundOpsTeamNonAdmin: PropTypes.array,
  selectedTasks: PropTypes.array,
  isInboundOpsTeamUser: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  isInboundOpsSupervisor: PropTypes.bool
};

export default connect(mapStateToProps)(CorrespondenceTableBuilder);
