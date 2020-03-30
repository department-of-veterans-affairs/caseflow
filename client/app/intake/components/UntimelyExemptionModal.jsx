import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { useSelector } from 'react-redux';

const UntimelyExemptionModal = ({
  formType,
  intakeData,
  currentIssue,
  onSubmit,
  submitText = 'Add this issue',
  onCancel,
  cancelText = 'Cancel adding this issue',
  onSkip,
  skipText = 'None of these match, see more options'
}) => {
  const { covidTimelinessExemption } = useSelector((state) => state.featureToggles);

  const [state, setState] = useState({
    untimelyExemption: '',
    untimelyExemptionNotes: '',
    untimelyExemptionCovid: ''
  });

  const buttons = useMemo(() => {
    const btns = [
      {
        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
        name: cancelText,
        onClick: onCancel
      },
      {
        classNames: ['usa-button', 'add-issue'],
        name: submitText,
        onClick: () => onSubmit({ ...state }),
        disabled: !state.untimelyExemption
      }
    ];

    if (onSkip) {
      btns.push({
        classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
        name: skipText,
        onClick: onSkip
      });
    }

    return btns;
  }, [cancelText, onCancel, submitText, state.untimelyExemption, skipText, onSkip]);

  const issueNumber = (intakeData.addedIssues || []).length + 1;
  const issue = currentIssue;

  return (
    <div className="intake-add-issues">
      <Modal buttons={buttons} visible closeHandler={onCancel} title={`Issue ${issueNumber} is an Untimely Issue`}>
        <p>
          <strong>Requested issue:</strong> {issue.description}
        </p>
        <p>The issue requested isn't usually eligible because its decision date is older than what's allowed.</p>
        <RadioField
          name="untimely-exemption"
          label="Did the applicant request an extension to the date requirements?"
          strongLabel
          vertical
          options={BOOLEAN_RADIO_OPTIONS}
          onChange={(untimelyExemption) => setState({ ...state, untimelyExemption })}
          value={state.untimelyExemption === null ? null : state.untimelyExemption.toString()}
        />

        {state.untimelyExemption === 'true' && (
          <>
            {covidTimelinessExemption && formType === 'higher_level_review' && (
              <RadioField
                name="untimelyExemptionCovid"
                label="Is the reason for requesting an extension related to COVID-19?"
                strongLabel
                vertical
                options={BOOLEAN_RADIO_OPTIONS}
                onChange={(untimelyExemptionCovid) => setState({ ...state, untimelyExemptionCovid })}
                value={state.untimelyExemptionCovid === null ? null : state.untimelyExemptionCovid.toString()}
              />
            )}

            <TextField
              name="Notes"
              optional
              strongLabel
              value={state.untimelyExemptionNotes}
              onChange={(untimelyExemptionNotes) => setState({ ...state, untimelyExemptionNotes })}
            />
          </>
        )}
      </Modal>
    </div>
  );
};

UntimelyExemptionModal.propTypes = {
  formType: PropTypes.string.isRequired,
  intakeData: PropTypes.object.isRequired,
  currentIssue: PropTypes.object.isRequired,
  onSubmit: PropTypes.func.isRequired,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  skipText: PropTypes.string
};

UntimelyExemptionModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default UntimelyExemptionModal;
