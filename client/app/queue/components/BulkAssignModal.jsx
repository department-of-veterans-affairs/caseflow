import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { withRouter } from 'react-router-dom';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';
import QueueFlowModal from './QueueFlowModal';
import Dropdown from '../../components/Dropdown';
import { regionalOfficeCity } from '../utils';
import { getUnassignedOrganizationalTasks } from '../selectors';
import { bulkAssignTasks, onReceiveQueue } from '../QueueActions';
import {
  setActiveOrganization
} from '../uiReducer/uiActions';

const BULK_ASSIGN_ISSUE_COUNT = [5, 10, 20, 30, 40, 50];

class BulkAssignModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showErrors: false,
      users: [],
      modal: {
        assignedUser: null,
        regionalOffice: null,
        taskType: null,
        numberOfTasks: null
      }
    };
  }

  componentDidMount() {
    ApiUtil.get(`/organizations/${this.organizationUrl()}/members.json`).then((resp) => {
      this.setState({ users: resp.body.members.data });
    }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  onFieldChange = (value, field) => {
    const newState = this.state.modal;

    newState[field] = value;
    this.setState({ modal: newState });
    this.forceUpdate();
  }

  generateErrors = () => {
    const requiredFields = ['assignedUser', 'taskType', 'numberOfTasks'];
    const undefinedFields = _.keys(_.omitBy(this.state.modal, _.isString));
    const errorFields = [];

    undefinedFields.forEach((field) => {
      if (requiredFields.includes(field)) {
        errorFields.push(field);
      }
    });

    return errorFields;
  }

  bulkAssignTasks = () => {
    this.setState({ showErrors: true });

    if (this.generateErrors().length === 0) {
      this.props.bulkAssignTasks(this.state.modal);

      const { taskType: task_type, numberOfTasks: task_count, assignedUser: assigned_to_id } = this.state.modal;
      const regionalOffice = _.uniq(this.props.tasks.filter((task) => {
        return regionalOfficeCity(task) === this.state.modal.regionalOffice;
      }))[0];
      const regionalOfficeKey = _.get(regionalOffice, 'closestRegionalOffice.key');

      const data = { bulk_task_assignment: {
        organization_url: this.organizationUrl(),
        regional_office: regionalOfficeKey,
        assigned_to_id,
        task_type,
        task_count }
      };

      return ApiUtil.post('/bulk_task_assignments', { data }).then(() => {
        this.props.history.push(`/organizations/${this.organizationUrl()}`);
        window.location.reload();
      }).
        catch(() => {
          // handle the error
        });
    }
  }

  getDisplayTextOption = (options) => {
    const optionsWithDisplayText = [
      {
        value: null,
        displayText: ''
      }
    ];

    options.forEach((option) => {
      if (option !== null) {
        if (typeof option === 'object') {
          optionsWithDisplayText.push(option);
        } else {
          optionsWithDisplayText.push(
            {
              value: option,
              displayText: option
            }
          );
        }
      }
    });

    return optionsWithDisplayText;
  }

  displayErrorMessage = (field) => {
    return this.state.showErrors && this.generateErrors().includes(field) ? 'Please select a value' : null;
  }

  filterTasks = (fieldName, fieldValue, tasks) => {
    let filteredTasks = tasks;

    filteredTasks = fieldValue ?
      _.filter(filteredTasks, { [fieldName]: fieldValue }) :
      filteredTasks;

    return filteredTasks;
  }

  generateUserOptions = () => {
    const users = this.state.users.map((user) => {
      return {
        value: user.id,
        displayText: `${user.attributes.css_id} ${user.attributes.full_name}`
      };
    });

    users.unshift({
      value: null,
      displayText: ''
    });

    return users;
  }

  generateRegionalOfficeOptions = () => {
    const options = _.uniq(this.props.tasks.map((task) => {
      return regionalOfficeCity(task);
    }));

    return this.getDisplayTextOption(options);
  }

  generateTaskTypeOptions = () => {
    let filteredTasks = this.props.tasks;

    if (this.state.modal.regionalOffice) {
      filteredTasks = filteredTasks.filter((task) => {
        return regionalOfficeCity(task);
      });
    }

    const taskOptions = _.uniq(filteredTasks.map((task) => task.type)).map((task) => {
      return {
        value: task,
        displayText: task.replace(/([a-z])([A-Z])/g, '$1 $2')
      };
    });

    taskOptions.unshift({
      value: null,
      displayText: ''
    });

    return taskOptions;
  }

  generateNumberOfTaskOptions = () => {
    const actualOptions = [];
    const issueCounts = BULK_ASSIGN_ISSUE_COUNT;
    let filteredTasks = this.props.tasks;

    // filter by regional office
    if (this.state.modal.regionalOffice) {
      filteredTasks = filteredTasks.filter((task) => {
        return regionalOfficeCity(task) === this.state.modal.regionalOffice;
      });
    }

    // filter by task type
    filteredTasks = this.filterTasks('type', this.state.modal.taskType, filteredTasks);

    for (let i = 0; i < issueCounts.length; i++) {
      if (filteredTasks && filteredTasks.length < issueCounts[i]) {
        actualOptions.push({
          value: filteredTasks.length,
          displayText: `${filteredTasks.length} (all available tasks)`
        });
        break;
      }
    }

    return actualOptions;
  }

  generateDropdown = (label, fieldName, options, isRequired) => <Dropdown
    name={label}
    options={options}
    value={this.state.modal[fieldName]}
    defaultText="Select"
    onChange={(value) => this.onFieldChange(value, fieldName)}
    errorMessage={this.displayErrorMessage(fieldName)}
    required={isRequired}
  />;

  organizationUrl = () => this.props.location.pathname.split('/')[2];

  render = () => <QueueFlowModal
    pathAfterSubmit={`/organizations/${this.organizationUrl()}`}
    button="Assign Tasks"
    submit={this.bulkAssignTasks}
    title="Bulk Assign Tasks">
    {this.generateDropdown('Assign to', 'assignedUser', this.generateUserOptions(), true)}
    {this.generateDropdown('Regional office', 'regionalOffice', this.generateRegionalOfficeOptions(), false)}
    {this.generateDropdown('Select task type', 'taskType', this.generateTaskTypeOptions(), true)}
    {this.generateDropdown('Select number of tasks to assign', 'numberOfTasks',
      this.generateNumberOfTaskOptions(), true)}
  </QueueFlowModal>;
}

const mapStateToProps = (state) => ({ tasks: getUnassignedOrganizationalTasks(state) });

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({ bulkAssignTasks,
    onReceiveQueue,
    setActiveOrganization }, dispatch)
);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(BulkAssignModal));
