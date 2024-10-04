import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useState, useEffect } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import TextField from '../../../components/TextField';
import SearchableDropdown from '../../../components/SearchableDropdown';
import TextareaField from '../../../components/TextareaField';
import Button from '../../../components/Button';
import ApiUtil from '../../../util/ApiUtil';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import DateSelector from '../../../components/DateSelector';
import {
  updateCmpInformation,
  setCreateRecordIsReadOnly,
  setCorrespondence
} from '../correspondenceReducer/reviewPackageActions';
import { validateDateNotInFuture } from '../../../intake/util/issues';

export const ReviewForm = (props) => {
  const { correspondenceTypeId, notes, vaDor, veteranFileNumber } = props;

  const correspondenceTypes = props.correspondenceTypes;
  const [dateError, setDateError] = useState(false);

  const handleCorrespondenceTypeEmpty = () => {
    if (correspondenceTypeId === null) {
      return 'Select...';
    }

    const type = correspondenceTypes.find((value) => value.id === correspondenceTypeId);

    return type.name;
  };

  // enable save button and enable return to queue
  const enableSaveButton = () => {
    props.setDisableSaveButton(false);
    props.setIsReturnToQueue(true);
  };

  const handleFileNumber = (value) => {
    // use reg expression to check the value only contains 9 numbers
    const isNumeric = ((/^\d{0,9}$/).test(value));

    // only attempt to update value if valid file number
    if (isNumeric) {
      props.setVeteranFileNumber(value);
      enableSaveButton();
    }
  };

  const handleChangeNotes = (value) => {
    props.setNotes(value);
    enableSaveButton();
  };

  const generateOptions = (options) =>
    options.map((option) => ({
      value: option.id,
      label: option.name,
      id: option.id,
    }));

  const handleSelectCorrespondenceType = (val) => {
    // update the correspondence type id and update the correspondence type
    // in the dropdown with placeholder
    props.setCorrespondenceTypeId(val.id);
    enableSaveButton();
  };

  const vaDORReadOnly = () => {
    if (props.userIsInboundOpsSupervisor) {
      return false;
    }

    return true;

  };

  const handleSelectVADOR = (val) => {
    // check for future issue
    const error = validateDateNotInFuture(val) ? false : 'Receipt date cannot be in the future';

    props.setVaDor(val);
    setDateError(error);

    // if no errors, enable the save button
    if (!error) {
      enableSaveButton();
    }
  };

  const handleSubmit = async () => {
    // disable the save button on submit
    props.setDisableSaveButton(true);

    props.setCreateRecordIsReadOnly('');
    const correspondence = props;
    const payloadData = {
      data: {
        correspondence: {
          notes,
          correspondence_type_id: correspondenceTypeId,
          va_date_of_receipt: vaDor
        },
        veteran: {
          file_number: veteranFileNumber
        }
      },
    };

    try {
      const response = await ApiUtil.patch(
        `/queue/correspondence/${correspondence.correspondence_uuid}/review_package`,
        payloadData
      );

      const { body } = response;

      // console.log(`response: ${JSON.stringify(response.body.correspondence, 1, 1)}`);
      // console.log(`body status: ${response.body.status}`);

      props.setIsReturnToQueue(false);
      if (body.status === 'ok') {
        // set error message to false and update redux stored correspondence
        props.setErrorMessage('');
        props.setCorrespondence(response.body.correspondence);

      }
    } catch (error) {
      const { body } = error.response;

      props.setErrorMessage(body.error);
    }
  };

  // enable save button if changes happen to form (with no errors)
  useEffect(() => {

    // error validation
    if (dateError || props.errorMessage) {
      props.setDisableSaveButton(true);
    }
  }, [handleChangeNotes, handleFileNumber, handleSelectCorrespondenceType, handleSelectVADOR]);

  const veteranFileNumStyle = () => {
    if (props.errorMessage) {
      return <div className="error-veternal-file-styling-review-form">
        <TextField
          label="Veteran file number"
          value={veteranFileNumber}
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
        value={veteranFileNumber}
        onChange={handleFileNumber}
        name="veteran-file-number-input"
        useAriaLabel
        errorMessage={props.errorMessage}
        readOnly={props.isReadOnly}
      />
    </div>;
  };

  const vaDORReadOnlyStyling = () => {
    if (vaDORReadOnly() || props.isReadOnly) {
      return <DateSelector
        className={['review-package-text-input-read-only']}
        class= "field-style-rp"
        label="VA DOR"
        name="date"
        type="date"
        onChange={handleSelectVADOR}
        value={vaDor}
        errorMessage={dateError}
        readOnly = {vaDORReadOnly() || props.isReadOnly}
      />;
    }

    return <DateSelector
      className={['review-package-date-input']}
      class= "field-style-rp"
      label="VA DOR"
      name="date"
      type="date"
      onChange={handleSelectVADOR}
      value={vaDor}
      errorMessage={dateError}
      readOnly = {vaDORReadOnly() || props.isReadOnly}
    />;
  };

  return (
    <React.Fragment>
      <div className="review-form-title-style">
        <h2>General Information</h2>
        <Button
          name="Save changes"
          href="/queue/correspondence/12/intake"
          classNames={['usa-button-primary']}
          disabled={props.disableSaveButton}
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
                  value={props.correspondence.veteranFullName}
                  readOnly
                  name="Veteran-name-display"
                  useAriaLabel
                />
              </div>
            </div>
            <div className= "nod-styling-review-form">
              <TextField
                name="correspondence-package-document-type"
                label="Package document type"
                value = {props.correspondence?.nod ? 'NOD' : 'Non-NOD'}
                readOnly
              />
            </div>

            <div className="review-package-field-styling">

              {vaDORReadOnlyStyling()}
            </div>
          </div>
          <div className="divide-textarea-styling-review-form">
            <div >
              <TextareaField
                id= "textarea-styling-review-form"
                name="Notes"
                value={notes}
                onChange={handleChangeNotes}
                disabled={props.isReadOnly}
              />
            </div>
            <div className="review-package-searchable-dropdown-div">
              <SearchableDropdown
                name="correspondence-dropdown"
                label="Correspondence type"
                options={generateOptions(props.correspondenceTypes)}
                onChange={handleSelectCorrespondenceType}
                readOnly={props.isReadOnly}
                placeholder={handleCorrespondenceTypeEmpty()}
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
  correspondenceTypeId: PropTypes.number,
  setCorrespondenceTypeId: PropTypes.func,
  notes: PropTypes.string,
  vaDor: PropTypes.string,
  veteranFileNumber: PropTypes.string,
  disableSaveButton: PropTypes.bool,
  setDisableSaveButton: PropTypes.func,
  setIsReturnToQueue: PropTypes.bool,
  setCreateRecordIsReadOnly: PropTypes.func,
  setCorrespondence: PropTypes.func,
  setErrorMessage: PropTypes.func,
  setVeteranFileNumber: PropTypes.func,
  setNotes: PropTypes.func,
  setVaDor: PropTypes.func,
  showModal: PropTypes.bool,
  handleModalClose: PropTypes.func,
  handleReview: PropTypes.func,
  errorMessage: PropTypes.any,
  isReadOnly: PropTypes.bool,
  userIsInboundOpsSupervisor: PropTypes.bool,
  correspondence: PropTypes.object,
  setCorrTypeSelected: PropTypes.bool,
  correspondenceTypes: PropTypes.array
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  packageDocumentType: state.reviewPackage.packageDocumentType
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  updateCmpInformation,
  setCreateRecordIsReadOnly,
  setCorrespondence
}, dispatch);

export default
connect(
  mapStateToProps,
  mapDispatchToProps,
)(ReviewForm);
