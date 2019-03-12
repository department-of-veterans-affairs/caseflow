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

  render() {
    const confirmButton = <Button classNames={['usa-button-secondary']} onClick={this.onModalChange}>
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
            options={this.props.attorneys}
            value={this.props.modal.assignedAttorney}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'assignedAttorney')}
            errorMessage={null}
            required
          />
          <RegionalOfficeDropdown
            value={this.props.modal.regionalOffice}
            onChange={(value) => this.onFieldChange(value, 'regionalOffice')}
            placeholder="Select"
            errorMessage={null}
          />
          <Dropdown
            name="Select task type"
            options={this.props.taskTypes}
            value={this.props.modal.taskType}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'taskType')}
            errorMessage={null}
            required
          />
          <Dropdown
            name="Select number of tasks to assign"
            options={this.props.numberOfTasks}
            value={this.props.modal.numberOfTasks}
            defaultText="Select"
            onChange={(value) => this.onFieldChange(value, 'numberOfTasks')}
            errorMessage={null}
            required
          />
      </Modal>
    )
  }
}

BulkAssignModal.propTypes = {
  attorneys: PropTypes.array.isRequired,
  handleFieldChange: PropTypes.func,
  handleModalToggle: PropTypes.func,
  modal: PropTypes.object.isRequired,
  numberOfTasks: PropTypes.array.isRequired,
  regionalOffices: PropTypes.array.isRequired,
  taskTypes: PropTypes.array.isRequired
};

export default BulkAssignModal;
