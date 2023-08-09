import React, { useMemo, useState } from 'react';
import { useDispatch } from 'react-redux';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import DateSelector from 'app/components/DateSelector';
import Modal from 'app/components/Modal';
import { addDecisionDate } from 'app/intake/actions/addIssues';
import { validateDateNotInFuture } from 'app/intake/util/issues';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';

const dateInputStyling = css({
  paddingTop: '24px'
});

const labelStyling = css({
  marginRight: '4px',
});

const AddDecisionDateModal = ({ closeHandler, currentIssue, index }) => {
  const [decisionDate, setDecisionDate] = useState('');
  const dispatch = useDispatch();

  // We should disable the save button if there has been no date selected
  // or if the date is in the future
  const isSaveDisabled = useMemo(() => {
    if (!decisionDate) {
      return true;
    }

    return !validateDateNotInFuture(decisionDate);
  }, [decisionDate]);

  const handleOnSubmit = () => {
    dispatch(addDecisionDate({ decisionDate, index }));
  };

  return (
    <div>
      <Modal
        buttons={[
          {
            classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: closeHandler
          },
          {
            classNames: ['usa-button-blue', 'save-issue'],
            disabled: isSaveDisabled,
            name: 'Save',
            onClick: () => {
              closeHandler();
              handleOnSubmit();
            }
          }
        ]}
        visible
        closeHandler={closeHandler}
        title="Add Decision Date"
      >
        <div>
          <strong {...labelStyling}>
            Issue:
          </strong>
          {currentIssue.category}
        </div>
        <div>
          <strong {...labelStyling}>
            Benefit type:
          </strong>
          {BENEFIT_TYPES[currentIssue.benefitType]}
        </div>
        <div>
          <strong {...labelStyling}>
            Issue decription:
          </strong>
          {currentIssue.nonRatingIssueDescription || currentIssue.description}
        </div>
        <div {...dateInputStyling}>
          <DateSelector
            label="Decision date"
            name="decision-date"
            noFutureDates
            onChange={(value) => setDecisionDate(value)}
            type="date"
            value={decisionDate}
          />
        </div>
      </Modal>
    </div>
  );
};

AddDecisionDateModal.propTypes = {
  closeHandler: PropTypes.func,
  currentIssue: PropTypes.object,
  index: PropTypes.number
};

export default AddDecisionDateModal;
