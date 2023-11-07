import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import { validateDateNotInFuture } from '../../../intake/util/issues';

class EditModal extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      VADORDate: '',
      packageDocument: '',
      dateError: ''
    };
  }

  getModalButtons() {
    const btns = [
      {
        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
        name: 'Cancel',
        onClick: this.props.onCancel
      },
      {
        classNames: ['usa-button', 'add-issue'],
        name: 'Save',
        onClick: this.onAddIssue,
        disabled: this.requiredFieldsMissing() || Boolean(this.state.dateError)
      }
    ];

    return btns;
  }

  requiredFieldsMissing() {
    const {
      VADORDate,
      packageDocument
    } = this.state;

    return (
      !VADORDate ||
      !packageDocument
    );
  }

  VADORDateOnChange = (value) => {
    this.setState({
      VADORDate: value,
      dateError: this.errorOnVADORDate(value)
    });
  };

  errorOnVADORDate = (value) => {
    if (value.length === 10) {
      const error = validateDateNotInFuture(value) ? null : 'Decision date cannot be in the future.';

      return error;
    }
  };

  render() {
    const { onCancel } = this.props;
    const { VADORDate, packageDocument } = this.state;

    return (
      <div>
        <Modal buttons={this.getModalButtons()} visible closeHandler={onCancel} title="Edit CMP information">
          <div className="add-nonrating-request-issue">
            <div className="decision-date">
              <DateSelector
                name="decision-date"
                label="VA DOR"
                strongLabel
                value={VADORDate}
                errorMessage={this.state.dateError}
                onChange={this.VADORDateOnChange}
                type="date"
              />
            </div>
            <br />
            <SearchableDropdown
              name="issue-category"
              label="Package document type"
              strongLabel
              placeholder="Select or enter..."
              // options={}
              value={packageDocument}
              // onChange={}
            />
          </div>
        </Modal>
      </div>
    );
  }
}

EditModal.propTypes = {
  onCancel: PropTypes.func,
};

export default EditModal;
