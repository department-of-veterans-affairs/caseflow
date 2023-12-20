import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';
import { css } from 'glamor';
import TextField from '../../../components/TextField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';

const flexDivStyling = css({
  display: 'flex',
});

const mainDiv = css(flexDivStyling, {
  justifyContent: 'space-between',
  width: '100%',
  gap: '3%',
  '@media (max-width: 600px)': {
    flexDirection: 'column'
  }
});

const divideStyling = css(flexDivStyling, {
  width: '50%',
  flexDirection: 'column',
  gap: '12%',
  '@media (max-width: 600px)': {
    width: '100%'
  }
});

const divideTextareaStyling = css(flexDivStyling, {
  width: '50%',
  flexDirection: 'column',
  '@media (max-width: 600px)': {
    width: '100%'
  }
});

const veternalFileStyling = css({
  width: '40%',
  '@media (max-width: 1081px)': {
    width: '100%',
  }
});

const errorVeternalFileStyling = css({
  width: '48%',
  marginTop: '-6.4rem',
  '@media (max-width: 1599px)': {
    width: '58%'
  }
});

const veternalNameStyling = css({
  width: '60%',
  '@media (max-width: 1081px)': {
    width: '100%'
  }
});

const inputStyling = css(flexDivStyling, {
  gap: '5%',
  '@media (max-width: 1081px)': {
    flexDirection: 'column'
  },
});

const tagStyling = css({
  '& .cf-select__control': {
    maxWidth: '63rem !important',
  },
});

const textareaStyling = css({
  maxWidth: '60rem'

});

const textareaWidth = css({
  height: '15rem',
  resize: 'none'

});

export const ReviewForm = (props) => {
  const handleFileNumber = (value) => {
    const isNumeric = value === '' || (/^\d{0,9}$/).test(value);

    if (isNumeric) {
      const updatedReviewDetails = {
        ...props.editableData,
        veteran_file_number: value,
      };

      props.setEditableData(updatedReviewDetails);
    }
  };

  const handleChangeNotes = (value) => {
    const updatedNotes = {
      ...props.editableData,
      notes: value,
    };

    props.setEditableData(updatedNotes);
  };

  const findDefaultVal = (array, id) => {
    const foundItem = array.find((item) => item.id === id);

    return foundItem ? { label: foundItem.name, value: foundItem.name } : null;
  };

  const defaultSelectedValue = findDefaultVal(
    props.reviewDetails.dropdown_values,
    props.editableData.default_select_value
  );

  const generateOptions = (options) =>
    options.map((option) => ({
      value: option.name,
      label: option.name,
      id: option.id,
    }));

  const fullName = (vetaranName) => {
    const {
      first_name: firstName = '',
      middle_initial: middleInitial = '',
      last_name: lastName = '',
    } = vetaranName;

    return `${firstName} ${middleInitial} ${lastName}`;
  };

  const handleSelect = (val) => {
    const updatedSelectedValue = {
      ...props.editableData,
      default_select_value: val.id,
    };

    props.setEditableData(updatedSelectedValue);
  };

  const handleSubmit = async () => {
    const correspondence = props;
    const payloadData = {
      data: {
        correspondence: {
          notes: props.editableData.notes,
          correspondence_type_id: props.editableData.default_select_value,
        },
        veteran: {
          file_number: props.editableData.veteran_file_number,
        },
      },
    };

    try {
      const response = await ApiUtil.patch(
        `/queue/correspondence/${correspondence.correspondence_uuid}`,
        payloadData
      );

      const { body } = response;

      if (body.status === 'ok') {
        props.fetchData();
        props.setDisableButton((current) => !current);
        props.setErrorMessage('');
      }
    } catch (error) {
      const { body } = error.response;

      props.setErrorMessage(body.error);
    }
  };

  return (
    <React.Fragment>
      <div {...flexDivStyling} style={{ gap: '20px', marginTop: '20px' }}>
        <h2>General Information</h2>
        <Button
          name="Save changes"
          href="/queue/correspondence/12/intake"
          classNames={['usa-button-primary']}
          disabled={!props.disableButton}
          onClick={handleSubmit}
        />
      </div>
      <AppSegment filledBackground noMarginTop>
        <main {...mainDiv}>
          <div {...divideStyling}>
            <div {...inputStyling}>
              <div {...props.errorMessage ? { ...errorVeternalFileStyling } : { ...veternalFileStyling }}>
                <TextField
                  label="Veteran file number"
                  value={props.editableData.veteran_file_number}
                  onChange={handleFileNumber}
                  name="veteran-file-number-input"
                  useAriaLabel
                  errorMessage={props.errorMessage}
                />
              </div>

              <div {...veternalNameStyling}>
                <TextField
                  label="Veteran name"
                  value={fullName(props.reviewDetails.veteran_name)}
                  readOnly
                  name="Veteran-name-display"
                  useAriaLabel
                />
              </div>

            </div>
            <div >

              <SearchableDropdown
                name="correspondence-dropdown"
                label="Correspondence type"
                styling={tagStyling}
                value={defaultSelectedValue}
                options={generateOptions(props.reviewDetails.dropdown_values)}
                onChange={handleSelect}
              />
            </div>

          </div>
          <div {...divideTextareaStyling}>
            <div>
              <TextareaField
                name="Notes"
                styling={textareaStyling}
                textAreaStyling={textareaWidth}
                value={props.editableData.notes}
                onChange={handleChangeNotes}
              />
            </div>
          </div>
          {props.showModal && (
            <Modal
              buttons={[
                {
                  classNames: ['cf-modal-link', 'cf-btn-link'],
                  name: 'Close',
                  onClick: props.handleModalClose },
                {
                  classNames: ['usa-button'],
                  name: 'Confirm',
                  onClick: props.handleReview,
                }
              ]}
              title="Return to queue"
              closeHandler={props.handleModalClose}>
              <span className="usa-input" style={{ marginBottom: '5px' }} tabIndex={0}>
                All unsaved changes made to this mail package will be lost<br />upon cancellation.
              </span>
            </Modal>
          )}
        </main>
      </AppSegment>
    </React.Fragment>
  );
};

ReviewForm.propTypes = {
  reviewDetails: PropTypes.shape({
    veteran_name: PropTypes.shape({
      first_name: PropTypes.string,
      middle_initial: PropTypes.string,
      last_name: PropTypes.string,
    }),
    dropdown_values: PropTypes.array,
  }),
  editableData: PropTypes.shape({
    notes: PropTypes.string,
    veteran_file_number: PropTypes.string,
    default_select_value: PropTypes.number,
  }),
  disableButton: PropTypes.bool,
  setEditableData: PropTypes.func,
  setDisableButton: PropTypes.func,
  setErrorMessage: PropTypes.func,
  fetchData: PropTypes.func,
  showModal: PropTypes.bool,
  handleModalClose: PropTypes.func,
  handleReview: PropTypes.func,
  errorMessage: PropTypes.string
};

export default ReviewForm;
