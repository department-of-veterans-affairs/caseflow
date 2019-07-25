import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { correctIssue } from '../actions/addIssues';
import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import {
  INTAKE_CORRECTION_TYPE_MODAL_TITLE,
  INTAKE_CORRECTION_TYPE_MODAL_COPY
} from '../../../COPY.json';

const correctionTypeOptions = [
  { value: 'control',
    displayText: 'Control' },
  { value: 'local_quality_error',
    displayText: 'Local Quality Error' },
  { value: 'national_quality_error',
    displayText: 'National Quality Error' }
];

class CorrectionTypeModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      correctionType: null
    };
  }

  handleSelect(correctionType) {
    this.setState({ correctionType });
  }

  render() {
    const {
      issueIndex,
      cancelText,
      onCancel,
      onClose,
      submitText,
      correctIssue
    } = this.props;

    return <div className="intake-correction-type">
      <Modal
        buttons={[
          {
            classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: cancelText || 'Cancel',
            onClick: onCancel
          },
          {
            classNames: ['usa-button-red', 'correction-type-submit'],
            name: submitText || 'Correct Issue',
            disabled: !this.state.correctionType,
            onClick: () => {
              correctIssue({ index: issueIndex,
                correctionType: this.state.correctionType });
              onClose();
            }
          }
        ]}
        visible
        closeHandler={onClose}
        title={INTAKE_CORRECTION_TYPE_MODAL_TITLE}
      >

        <div>
          <p>{INTAKE_CORRECTION_TYPE_MODAL_COPY}</p>

          <RadioField
            vertical
            required
            // label="Select Correction Type"
            hideLabel
            name="correctionType"
            options={correctionTypeOptions}
            value={this.state.correctionType}
            onChange={(val) => this.handleSelect(val)}
          />
        </div>

      </Modal>
    </div>;
  }
}

CorrectionTypeModal.propTypes = {
  onCancel: PropTypes.func,
  onClose: PropTypes.func,
  cancelText: PropTypes.string,
  submitText: PropTypes.string,
  issueIndex: PropTypes.number
};

export default connect(
  null,
  (dispatch) => bindActionCreators({
    correctIssue
  }, dispatch)
)(CorrectionTypeModal);
