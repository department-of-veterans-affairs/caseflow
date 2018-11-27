import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  tasksByOrganization
} from './selectors';

import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

const styles = {
  container: css({
    position: 'relative'
  }),
  dropdownTrigger: css({
    marginRight: 0
  }),
  dropdownButton: css({
    position: 'absolute',
    top: '40px',
    right: '40px'
  }),
  dropdownList: css({
    top: '3.55rem',
    right: '0',
    width: '26rem'
  })
};

class OrganizationQueue extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      menu: false
    };
  }

  onMenuClick = () => {
    this.setState((prevState) => ({
      menu: !prevState.menu
    }));
  };

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    let dropdown;
    const tabs = [
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
        page: <TaskTableTab
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.unassignedTasks}
        />
      },
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE, this.props.assignedTasks.length),
        page: <TaskTableTab
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.assignedTasks}
        />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <TaskTableTab
          description={
            sprintf(COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.completedTasks}
        />
      }
    ];

    const dropdownButtonList = (orgs) => {
      const url = window.location.pathname.split('/');
      const location = url[url.length - 1];

      return <ul className="cf-dropdown-menu active" {...styles.dropdownList}>
        <li key={0}>
          <Link className="usa-button-secondary usa-button"
            href="/queue" onClick={this.onMenuClick}>
            {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_OWN_CASES_LABEL}
          </Link>
        </li>

        {orgs.map((org, index) => {
          const href = (location === org.url) ? "javascript:;" : `/organizations/${org.url}`;

          return <li key={index + 1}>
            <Link className="usa-button-secondary usa-button"
              href={href} onClick={this.onMenuClick}>
              {sprintf(COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_TEAM_CASES_LABEL, org.name)}
            </Link>
          </li>;
        })}
      </ul>;
    };

    if (this.props.organizations.length > 0) {
      dropdown = <div className="cf-dropdown" {...styles.dropdownButton}>
        <a onClick={this.onMenuClick}
          className="cf-dropdown-trigger usa-button usa-button-secondary"
          {...styles.dropdownTrigger}>
          {COPY.CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL}
        </a>
        {this.state.menu && dropdownButtonList(this.props.organizations) }
      </div>;
    }

    return <AppSegment filledBackground styling={styles.container}>
      <div>
        <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>

        {dropdown}

        <TabWindow
          name="tasks-organization-queue"
          tabs={tabs}
        />
      </div>
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  tasks: PropTypes.array.isRequired
};

const mapStateToProps = (state) => ({
  organizations: state.ui.organizations,
  unassignedTasks: getUnassignedOrganizationalTasks(state),
  assignedTasks: getAssignedOrganizationalTasks(state),
  completedTasks: getCompletedOrganizationalTasks(state),
  tasks: tasksByOrganization(state)
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
  <p>{description}</p>
  <TaskTable
    includeDetailsLink
    includeTask
    includeType
    includeDocketNumber
    includeDaysWaiting
    includeReaderLink
    tasks={tasks}
  />
</React.Fragment>;
