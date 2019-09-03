import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import { INTAKE_CORRECTION_TYPE_MODAL_TITLE, INTAKE_CORRECTION_TYPE_MODAL_COPY } from '../../../COPY.json';

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

  handleSubmit = () => {
    const { correctionType } = this.state;

    this.props.onSubmit({ correctionType });
  };

  getModalButtons() {
    const btns = [
      {
        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
        name: this.props.cancelText,
        onClick: this.props.onCancel
      },
      {
        classNames: ['usa-button', 'add-issue', 'correction-type-submit'],
        name: this.props.submitText,
        onClick: this.handleSubmit,
        disabled: !this.state.correctionType
      }
    ];

    if (this.props.onSkip) {
      btns.push({
        classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
        name: this.props.skipText,
        onClick: this.props.onSkip
      });
    }

    return btns;
  }

  render() {
    const { onCancel } = this.props;

    return (
      <div className="intake-correction-type">
        <Modal
          buttons={this.getModalButtons()}
          visible
          closeHandler={onCancel}
          title={INTAKE_CORRECTION_TYPE_MODAL_TITLE}
        >
          <div>
            <p>{INTAKE_CORRECTION_TYPE_MODAL_COPY}</p>

            <RadioField
              vertical
              required
              hideLabel
              name="correctionType"
              options={correctionTypeOptions}
              value={this.state.correctionType}
              onChange={(val) => this.handleSelect(val)}
            />
          </div>
        </Modal>
      </div>
    );
  }
}

CorrectionTypeModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
  cancelText: PropTypes.string,
  submitText: PropTypes.string,
  issueIndex: PropTypes.number
};

CorrectionTypeModal.defaultProps = {
  submitText: 'Next',
  cancelText: 'Cancel',
  skipText: 'None of these match, see more options'
};

export default CorrectionTypeModal;
