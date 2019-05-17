import * as React from 'react';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';
import { withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Dropdown from '../../components/Dropdown';
import { onReceiveAmaTasks } from '../QueueActions';

import {
  requestSave
} from '../uiReducer/uiActions';

const BULK_ASSIGN_ISSUE_COUNT = [5, 10, 20, 30, 40, 50];

class BulkAssignModal extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      showModal: false,
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

  submit = () => {
    const taskIds = this.getFilteredTaskIds();
    const assignedUser = this.state.modal.assignedUser;
    const numberOfTasks = this.state.modal.numberOfTasks;
    const payload = {
      data: { bulk_assign:
        { parent_ids: taskIds,
          assigned_to_id: assignedUser,
          number_of_tasks: numberOfTasks
        }
      }
    };

    return this.props.requestSave('/tasks/bulk_assign/', payload, "").
      then((resp) => {
        const response = JSON.parse(resp.text);
        this.props.assignTasks(this.state.modal);
        this.props.onReceiveAmaTasks(response.tasks.data);
      }).
      catch(() => {
        // handle the error from the frontend
      });
  }

  componentDidMount() {
    let fetchedUsers;

    if (this.props.organizationUrl) {
      ApiUtil.get(`/organizations/${this.props.organizationUrl}/users.json`).then((resp) => {
        fetchedUsers = resp.body.organization_users.data;

        this.setState({ users: fetchedUsers });
      });
    }
  }

  handleModalToggle = () => {
    const modalStatus = this.state.showModal;

    this.setState({ showModal: !modalStatus });
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

  getFilteredTaskIds = () => {
    let filteredTasks = this.props.tasks;

    filteredTasks = this.filterTasks('closestRegionalOffice', this.state.modal.regionalOffice, filteredTasks);
    filteredTasks = this.filterTasks('type', this.state.modal.taskType, filteredTasks);

    return filteredTasks.map((task) => task.taskId);
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
    const options = _.uniq(this.props.tasks.map((task) => task.closestRegionalOffice));

    return this.getDisplayTextOption(options);
  }

  generateTaskTypeOptions = () => {
    let filteredTasks = this.props.tasks;

    if (this.state.modal.regionalOffice) {
      filteredTasks = _.filter(filteredTasks, { closestRegionalOffice: this.state.modal.regionalOffice });
    }

    const uniqueTasks = _.uniq(filteredTasks.map((task) => task.type));
    const taskOptions = uniqueTasks.map((task) => {
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
    const issueCounts = this.props.issueCountOptions || BULK_ASSIGN_ISSUE_COUNT;
    const filteredTasksIds = this.getFilteredTaskIds();

    for (let i = 0; i < issueCounts.length; i++) {
      if (filteredTasksIds && filteredTasksIds.length < issueCounts[i]) {
        actualOptions.push({
          value: filteredTasksIds.length,
          displayText: `${filteredTasksIds.length} (all available tasks)`
        });

        break;
      } else {
        actualOptions.push({
          value: issueCounts[1],
          displayText: issueCounts[1]
        });
      }
    }

    return actualOptions;
  }

  generateDropdown = (label, fieldName, options, isRequired) => {
    return (
      <Dropdown
        name={label}
        options={options}
        value={this.state.modal[fieldName]}
        defaultText="Select"
        onChange={(value) => this.onFieldChange(value, fieldName)}
        errorMessage={this.displayErrorMessage(fieldName)}
        required={isRequired}
      />
    );
  }

  render() {
    const isBulkAssignEnabled = this.props.enableBulkAssign && this.props.organizationUrl;
    const bulkAssignButton = <Button classNames={['bulk-assign-button']} onClick={this.handleModalToggle}>
      Assign Tasks</Button>;
    const confirmButton = <Button classNames={['usa-button-secondary']} onClick={this.submit}>
      Assign</Button>;
    const cancelButton = <Button linkStyling onClick={this.handleModalToggle}>Cancel</Button>;
    const modal = (
      <Modal
        title="Assign Tasks"
        closeHandler={this.handleModalToggle}
        confirmButton={confirmButton}
        cancelButton={cancelButton} >
        {this.generateDropdown('Assign to', 'assignedUser', this.generateUserOptions(), true)}
        {this.generateDropdown('Regional office', 'regionalOffice', this.generateRegionalOfficeOptions(), false)}
        {this.generateDropdown('Select task type', 'taskType', this.generateTaskTypeOptions(), true)}
        {this.generateDropdown('Select number of tasks to assign', 'numberOfTasks',
          this.generateNumberOfTaskOptions(), true)}
      </Modal>
    );

    return (
      <div>
        {isBulkAssignEnabled && this.state.showModal && modal}
        {isBulkAssignEnabled && bulkAssignButton}
      </div>
    );
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  requestSave,
  onReceiveAmaTasks
}, dispatch);

export default (withRouter(connect(null, mapDispatchToProps)(BulkAssignModal)));
