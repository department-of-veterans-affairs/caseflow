import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';
import TextField from '../../../components/TextField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';

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

  const generateOptions = (options) =>
    options.map((option) => ({
      value: option.id,
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

  const veteranFileNumStyle = () => {
    if (props.errorMessage) {
      return <div className="error-veternal-file-styling-review-form">
        <TextField
          label="Veteran file number"
          value={props.editableData.veteran_file_number}
          onChange={handleFileNumber}
          name="veteran-file-number-input"
          useAriaLabel
          errorMessage={props.errorMessage}
          readOnly={props.isReadOnly}
        />
      </div>;
    }

    return <div className="veternal-file-styling-review-form">
      <TextField
        label="Veteran file number"
        value={props.editableData.veteran_file_number}
        onChange={handleFileNumber}
        name="veteran-file-number-input"
        useAriaLabel
        errorMessage={props.errorMessage}
        readOnly={props.isReadOnly}
      />
    </div>;

  };

  return (
    <React.Fragment>
      <div className="review-form-title-style">
        <h2>General Information</h2>
        <Button
          name="Save changes"
          href="/queue/correspondence/12/intake"
          classNames={['usa-button-primary']}
          disabled={!props.disableButton || props.isReadOnly}
          onClick={handleSubmit}
        />
      </div>
      <AppSegment filledBackground noMarginTop>
        <main className="main-div-review-form">
          <div className="divide-styling-review-form">
            <div className="input-styling-review-form" >
              {veteranFileNumStyle()}
              <div className="veternal-name-styling-review-form ">
                <TextField
                  label="Veteran name"
                  value={fullName(props.reviewDetails.veteran_name)}
                  readOnly
                  name="Veteran-name-display"
                  useAriaLabel
                />
              </div>

            </div>
            <div className= "tag-styling-review-form">

              <SearchableDropdown
                name="correspondence-dropdown"
                label="Correspondence type"
                options={generateOptions(props.reviewDetails.dropdown_values)}
                onChange={handleSelect}
                readOnly={props.isReadOnly}
                placeholder="Select..."
              />
            </div>

          </div>
          <div className="divide-textarea-styling-review-form">
            <div >
              <TextareaField
                id= "textarea-styling-review-form"
                name="Notes"
                value={props.editableData.notes}
                onChange={handleChangeNotes}
                disabled={props.isReadOnly}
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
              <span tabIndex={0}>
                All unsaved changes made to this mail package will be lost<br />upon returning to your queue.
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
    correspondence_type_id: PropTypes.number
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
  errorMessage: PropTypes.string,
  isReadOnly: PropTypes.bool
};

export default ReviewForm;
