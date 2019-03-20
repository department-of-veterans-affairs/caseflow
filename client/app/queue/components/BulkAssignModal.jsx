import * as React from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Dropdown from '../../components/Dropdown';
import RegionalOfficeDropdown from '../../components/DataDropdowns/RegionalOffice';

class BulkAssignModal extends React.PureComponent {
  onFieldChange = (value, field) => {
    this.props.handleFieldChange(value, field);
  }

  onModalChange = () => {
    this.props.handleModalToggle();
  }

  getDisplayTextOption = (options) => {
    const optionsWithDisplayText = [
      {
        value: null,
        displayText: ''
      }
    ];

    options.forEach((option) => {
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
    });

    return optionsWithDisplayText;
  }

  displayErrorMessage = (field) => {
    return this.props.errors.includes(field) ? 'Please select a value' : null;
  }

  render() {
    const confirmButton = <Button classNames={['usa-button-secondary']} onClick={() => {}}>
      Assign
    </Button>;
    const cancelButton = <Button linkStyling onClick={this.onModalChange}>Cancel</Button>;

    return (
      <Modal
        title="Assign Tasks"
        closeHandler={this.onModalChange}
        confirmButton={confirmButton}
        cancelButton={cancelButton} >
          <Dropdown
            name="Assign to"
            options={this.getDisplayTextOption(this.props.users)}
            value={this.props.modal.assignedUser}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'assignedUser')}
            errorMessage={this.displayErrorMessage('assignedUser')}
            required
          />
          <Dropdown
            name="Regional office"
            options={this.getDisplayTextOption(this.props.regionalOffices)}
            value={this.props.modal.regionalOffice}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'regionalOffice')}
            errorMessages={this.displayErrorMessage('regionalOffice')}
          />
          <Dropdown
            name="Select task type"
            options={this.getDisplayTextOption(this.props.taskTypes)}
            value={this.props.modal.taskType}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'taskType')}
            errorMessage={this.displayErrorMessage('taskType')}
            required
          />
          <Dropdown
            name="Select number of tasks to assign"
            options={this.getDisplayTextOption(this.props.numberOfTasks)}
            value={this.props.modal.numberOfTasks}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'numberOfTasks')}
            errorMessage={this.displayErrorMessage('numberOfTasks')}
            required
          />
      </Modal>
    )
  }
}

BulkAssignModal.propTypes = {
  users: PropTypes.array.isRequired,
  handleFieldChange: PropTypes.func,
  handleModalToggle: PropTypes.func,
  modal: PropTypes.object.isRequired,
  numberOfTasks: PropTypes.array.isRequired,
  regionalOffices: PropTypes.array.isRequired,
  taskTypes: PropTypes.array.isRequired
};

export default BulkAssignModal;

          // <RegionalOfficeDropdown
          //   value={this.props.modal.regionalOffice}
          //   onChange={(value) => this.onFieldChange(value, 'regionalOffice')}
          //   placeholder="Select"
          //   errorMessage={null}
          // />
