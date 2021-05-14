// React
import React, { useState } from 'react';
// Libraries
import PropTypes from 'prop-types';
// Caseflow
import Modal from '../../../components/Modal';
import { TimeSelect } from '../scheduleHearing/TimeSelect';
import { InfoAlert } from '../scheduleHearing/InfoAlert';
import { css } from 'glamor';

export const TimeModal = ({ onCancel, onConfirm, ro, title, hearingDayDate }) => {
  // Error message state
  const [error, setError] = useState('');
  // Control the TimeSelect component
  const [selectedOption, setSelectedOption] = useState();
  // Check if we have a value, if yes setError, if not, format and submit.
  const handleConfirm = () => {
    if (!selectedOption) {
      setError('Please enter a hearing start time.');
    }
    if (selectedOption) {
      const formattedValue = selectedOption.value.tz('America/New_York').format('HH:mm');

      window.analyticsEvent('Hearings', 'Schedule Veteran – Choose a custom time', formattedValue);
      onConfirm(selectedOption.value);
    }
  };

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Choose time',
          onClick: handleConfirm
        },
      ]}
      closeHandler={onCancel}
      id="custom-time-modal"
    >
      <div {...css({ height: '200px' })}>
        <div {...css({ fontWeight: 'bold' })}>
          Choose a hearing start time for <span {...css({ whiteSpace: 'nowrap' })}>{ro.city}</span>
        </div>
        <div>Enter time as h:mm AM/PM, for example "1:00 PM"</div>

        {error && <div {...css({ color: 'red', paddingTop: '16px' })}>{error}</div>}

        <TimeSelect
          roTimezone={ro.timezone}
          onSelect={setSelectedOption}
          error={error}
          clearError={() => setError('')}
          hearingDayDate={hearingDayDate}
        />

        {ro.timezone !== 'America/New_York' && selectedOption &&
          <InfoAlert timeString={selectedOption?.value.tz('America/New_York').format('h:mm A')} />
        }

      </div>
    </Modal>
  );
};

TimeModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  ro: PropTypes.shape({
    city: PropTypes.string,
    timezone: PropTypes.string,
  }),
  title: PropTypes.string,
  hearingDayDate: PropTypes.string
};

