import * as React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import ApiUtil from '../../util/ApiUtil';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Dropdown from '../../components/Dropdown';

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

  bulkAssignTasks = () => {
    this.setState({ showErrors: true });

    if (this.generateErrors().length === 0) {
      this.props.assignTasks(this.state.modal);
      this.handleModalToggle();
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
        value: user.attributes.css_id,
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
    let filteredTasks = this.props.tasks;

    // filter by regional office
    filteredTasks = this.filterTasks('closestRegionalOffice', this.state.modal.regionalOffice, filteredTasks);

    // filter by task type
    filteredTasks = this.filterTasks('type', this.state.modal.taskType, filteredTasks);

    for (let i = 0; i < issueCounts.length; i++) {
      if (filteredTasks && filteredTasks.length < issueCounts[i]) {
        actualOptions.push({
          value: filteredTasks.length,
          displayText: `${filteredTasks.length} (all available tasks)`
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
    const confirmButton = <Button classNames={['usa-button-secondary']} onClick={this.bulkAssignTasks}>
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

BulkAssignModal.propTypes = {
  enableBulkAssign: PropTypes.bool,
  tasks: PropTypes.array.isRequired,
  organizationUrl: PropTypes.string,
  assignTasks: PropTypes.func.isRequired,
  issueCountOptions: PropTypes.array
};

export default BulkAssignModal;
