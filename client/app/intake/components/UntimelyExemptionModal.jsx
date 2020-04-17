import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { useSelector } from 'react-redux';
import Checkbox from '../../components/Checkbox';
import { css } from 'glamor';
import COPY from '../../../COPY';

const generateButtons = ({ cancelText, onCancel, onSubmit, submitText, skipText, onSkip, state, isInvalid }) => {
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
      disabled: isInvalid()
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
};

export const UntimelyExemptionModal = ({
  intakeData,
  currentIssue,
  onSubmit,
  formType,
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
    untimelyExemptionCovid: false
  });

  const isInvalid = () => !state.untimelyExemption;

  const buttons = useMemo(
    () =>
      generateButtons({
        cancelText,
        onCancel,
        onSubmit,
        submitText,
        skipText,
        onSkip,
        state,
        isInvalid
      }),
    [cancelText, onCancel, submitText, skipText, onSkip, state]
  );

  const issueNumber = (intakeData.addedIssues || []).length + 1;
  const issue = currentIssue;

  const descriptionText = () => {
    let errorMsg = '';
    const vacolsIssueIneligible = issue.vacolsId && !issue.eligibleForSocOptIn;
    const requestIssueUnTimely = !issue.timely && !(formType === 'supplemental_claim');

    if (covidTimelinessExemption) {
      if (vacolsIssueIneligible && requestIssueUnTimely) {
        errorMsg = COPY.INTAKE_REQUEST_ISSUE_AND_LEGACY_ISSUE_UNTIMELY;
      } else if (vacolsIssueIneligible) {
        errorMsg = COPY.INTAKE_LEGACY_ISSUE_UNTIMELY;
      } else if (requestIssueUnTimely) {
        errorMsg = COPY.INTAKE_REQUEST_ISSUE_UNTIMELY;
      }

    } else {
      errorMsg = COPY.INTAKE_REQUEST_ISSUE_UNTIMELY;
    }

    return errorMsg;
  };

  return (
    <div className="intake-add-issues">
      <Modal buttons={buttons} visible closeHandler={onCancel} title={`Issue ${issueNumber} is an Untimely Issue`}>
        <p>
          <strong>Requested issue:</strong> {issue.description}
        </p>
        <p {...css({ marginBottom: '20px !important' })}>
          {descriptionText()}
        </p>
        <RadioField
          name="untimely-exemption"
          label="Did the applicant request an extension to the date requirements?"
          strongLabel
          vertical
          options={BOOLEAN_RADIO_OPTIONS}
          onChange={(val) => setState({ ...state, untimelyExemption: val })}
          value={state.untimelyExemption === null ? null : state.untimelyExemption.toString()}
        />

        {state.untimelyExemption === 'true' && (
          <>
            {covidTimelinessExemption && (
              <Checkbox
                name="untimelyExemptionCovid"
                label="This request is related to COVID-19"
                onChange={(val) => setState({ ...state, untimelyExemptionCovid: val })}
                value={state.untimelyExemptionCovid}
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
  intakeData: PropTypes.object.isRequired,
  currentIssue: PropTypes.object.isRequired,
  onSubmit: PropTypes.func.isRequired,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  formType: PropTypes.string,
  skipText: PropTypes.string
};

UntimelyExemptionModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default UntimelyExemptionModal;
