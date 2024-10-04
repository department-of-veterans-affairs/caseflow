import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import moment from 'moment';
import DateSelector from '../../components/DateSelector';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';
import { editCorrespondenceGeneralInformation } from
  '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceEditGeneralInformationModal = (props) => {
  const { correspondenceInfo, correspondenceTypes, handleEditGeneralInformationModal } = props;
  const [changeVaDor, setChangeVaDor] = useState(
    moment((correspondenceInfo?.vaDateOfReceipt)).format('YYYY-MM-DD')
  );
  const [changeCorrespondenceTypeId, setChangeCorrespondenceTypeId] = useState(
    // eslint-disable-next-line camelcase
    correspondenceInfo?.correspondence_type_id
  );
  const [changeNotes, setChangeNotes] = useState(correspondenceInfo?.notes);
  const [dateError, setDateError] = useState(false);
  const [saveButton, setSaveButton] = useState(true);

  // Handling VA DOR changes
  const validateDateNotInFuture = (date) => {
    const currentDate = new Date();
    const enteredDate = new Date(date);

    if (currentDate < enteredDate) {
      return false;
    }

    return true;
  };

  const handleSelectVaDor = (value) => {
    // Check for future date
    const error = validateDateNotInFuture(value) ? false : 'Receipt date cannot be in the future';

    setChangeVaDor(value);
    setDateError(error);

    // If no errors, enable the save button
    if (!error) {
      setSaveButton(false);
    }
  };

  // Handling Correspondence changes
  const generateOptions = (options) =>
    options?.map((option) => ({
      value: option.id,
      label: option.name,
      id: option.id,
    }));

  const handleSelectCorrespondenceType = (value) => {
    // Update the corresppondence type and type id with placeholder
    setChangeCorrespondenceTypeId(value.id);
    setSaveButton(false);
  };

  const handleCorrespondenceTypeEmpty = () => {
    // eslint-disable-next-line camelcase
    if (correspondenceInfo?.correspondence_type_id === null) {
      return 'Select...';
    }

    // eslint-disable-next-line camelcase
    const type = correspondenceTypes?.find((value) => value?.id === correspondenceInfo?.correspondence_type_id);

    return type?.name;
  };

  // Handling Notes Changes
  const handleChangeNotes = (value) => {
    setChangeNotes(value);
    setSaveButton(false);
  };

  // Handling Submit
  const handleSubmit = async () => {
    // Disable the save button on submit
    setSaveButton(true);

    const payload = {
      data: {
        correspondence: {
          va_date_of_receipt: changeVaDor,
          correspondence_type_id: changeCorrespondenceTypeId,
          notes: changeNotes
        }
      }
    };

    await (props.editCorrespondenceGeneralInformation(payload, correspondenceInfo.uuid));

    handleEditGeneralInformationModal();
  };

  // useEffects to activate save button
  // enable save button if changes happen to form (with no errors)
  useEffect(() => {
    // error validation
    if (dateError || props?.errorMessage) {
      setSaveButton(true);
    }
  }, [handleSelectVaDor, handleSelectCorrespondenceType, handleChangeNotes]);

  return (
    <QueueFlowModal
      title={COPY.CORRESPONDENCE_EDIT_GENERAL_INFORMATION_MODAL_TITLE}
      button={COPY.MODAL_SAVE_BUTTON}
      submitDisabled={saveButton}
      // eslint-disable-next-line camelcase
      pathAfterSubmit={correspondenceInfo?.redirect_after ??
         `/queue/correspondence/${correspondenceInfo.uuid}`}
      submit={handleSubmit}
      onCancel={handleEditGeneralInformationModal}
    >
      <DateSelector
        class= "field-style-rp"
        label="VA DOR"
        name="date"
        type="date"
        onChange={handleSelectVaDor}
        value={changeVaDor}
        errorMessage={dateError}
      />
      <br></br>
      <SearchableDropdown
        name="correspondence-dropdown"
        label="Correspondence type"
        options={generateOptions(props?.correspondenceTypes)}
        onChange={handleSelectCorrespondenceType}
        placeholder={handleCorrespondenceTypeEmpty()}
      />
      <br></br>
      <TextareaField
        name="Notes"
        id="taskInstructions"
        onChange={handleChangeNotes}
        value={changeNotes}
      />
    </QueueFlowModal>
  );
};

CorrespondenceEditGeneralInformationModal.propTypes = {
  correspondence_uuid: PropTypes.string,
  editCorrespondenceGeneralInformation: PropTypes.func,
  team: PropTypes.string,
  correspondenceTypes: PropTypes.array,
  correspondenceTypeId: PropTypes.number,
  setCorrespondenceTypeId: PropTypes.func,
  notes: PropTypes.string,
  vaDateOfReceipt: PropTypes.string,
  setSaveButton: PropTypes.bool,
  setCorrespondence: PropTypes.func,
  setErrorMessage: PropTypes.func,
  setNotes: PropTypes.func,
  setVaDor: PropTypes.func,
  errorMessage: PropTypes.string,
  userIsInboundOpsSupervisor: PropTypes.bool,
  correspondenceInfo: PropTypes.object,
  handleEditGeneralInformationModal: PropTypes.func
};

const mapStateToProps = (state) => ({
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  editCorrespondenceGeneralInformation
}, dispatch);

export default (withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceEditGeneralInformationModal)
));
