import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import ApiUtil from '../../util/ApiUtil';

import DateSelector from '../../components/DateSelector';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';
import COPY from '../../../COPY';
import QueueFlowModal from './QueueFlowModal';

import { correspondenceInfo } from
  '../correspondence/correspondenceDetailsReducer/correspondenceDetailsActions';

const CorrespondenceEditGeneralInformationModal = (props) => {
  const correspondenceTypes = props.correspondenceTypes;

  const { vaDor, correspondenceTypeId, notes, veteranFileNumber, handleEditGeneralInformationModal} = props;
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
    // check for future issue
    const error = validateDateNotInFuture(value) ? false : 'Receipt date cannot be in the future';

    props.setVaDor(value);
    setDateError(error);

    // if no errors, enable the save button
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
    // update the correspondence type id and update the correspondence type
    // in the dropdown with placeholder
    props.setCorrespondenceTypeId(value.id);
    setSaveButton(false);
  };

  const handleCorrespondenceTypeEmpty = () => {
    if (correspondenceTypeId === null) {
      return 'Select...';
    }

    const type = correspondenceTypes.find((value) => value.id === correspondenceTypeId);
    // const type = 'Abeyance';

    return type.name;
  };

  // Handling Notes Changes
  const handleChangeNotes = (value) => {
    props.setNotes(value);
    setSaveButton(false);
  };

  // Handling Submit
  const handleSubmit = async () => {
    // disable the save button on submit
    setSaveButton(true);

    // props.setCreateRecordIsReadOnly('');
    const correspondence = props;
    const payloadData = {
      data: {
        correspondence: {
          va_date_of_receipt: vaDor,
          correspondence_type_id: correspondenceTypeId,
          notes
        },
        veteran: {
          file_number: veteranFileNumber
        }
      },
    };

    try {
      const response = await ApiUtil.patch(
        `/queue/correspondence/${correspondence.correspondence_uuid}/edit_general_information"`,
        payloadData
      );

      const { body } = response;

      // console.log(`response: ${JSON.stringify(response.body.correspondence, 1, 1)}`);
      // console.log(`body status: ${response.body.status}`);

      if (body.status === 'ok') {
        // set error message to false and update redux stored correspondence
        props.setErrorMessage('');
        props.correspondenceInfo(response.body.correspondence);

      }
    } catch (error) {
      const { body } = error.response;

      props.setErrorMessage(body.error);
    }
  };

  // useEffects to activate save button
  // enable save button if changes happen to form (with no errors)
  useEffect(() => {
    // error validation
    if (dateError || props.errorMessage) {
      setSaveButton(true);
    }
  }, [handleSelectVaDor, handleSelectCorrespondenceType, handleChangeNotes]);

  return (
    <QueueFlowModal
      title={COPY.CORRESPONDENCE_EDIT_GENERAL_INFORMATION_MODAL_TITLE}
      button={COPY.MODAL_SAVE_BUTTON}
      submitDisabled={saveButton}
      pathAfterSubmit={`/queue/correspondence/${props.correspondence_uuid}`}
      submit={handleSubmit}
      onCancel={handleEditGeneralInformationModal}
    >
      <DateSelector
        class= "field-style-rp"
        label="VA DOR"
        name="date"
        type="date"
        onChange={handleSelectVaDor}
        value={vaDor}
        errorMessage={dateError}
      />
      <br></br>
      <SearchableDropdown
        name="correspondence-dropdown"
        label="Correspondence type"
        options={generateOptions(props.correspondenceTypes)}
        onChange={handleSelectCorrespondenceType}
        placeholder={handleCorrespondenceTypeEmpty()}
      />
      <br></br>
      <TextareaField
        name="Notes"
        id="taskInstructions"
        onChange={handleChangeNotes}
        value={notes}
      />
    </QueueFlowModal>
  );
};

CorrespondenceEditGeneralInformationModal.propTypes = {
  correspondence_uuid: PropTypes.string,
  correspondenceInfo: PropTypes.func,
  team: PropTypes.string,
  correspondenceTypes: PropTypes.array,
  correspondenceTypeId: PropTypes.number,
  setCorrespondenceTypeId: PropTypes.func,
  notes: PropTypes.string,
  vaDor: PropTypes.string,
  veteranFileNumber: PropTypes.string,
  setSaveButton: PropTypes.bool,
  setCorrespondence: PropTypes.func,
  setErrorMessage: PropTypes.func,
  setVeteranFileNumber: PropTypes.func,
  setNotes: PropTypes.func,
  setVaDor: PropTypes.func,
  errorMessage: PropTypes.any,
  userIsInboundOpsSupervisor: PropTypes.bool,
  correspondence: PropTypes.object
};

const mapStateToProps = (state) => ({
  correspondence: state.correspondenceDetails.correspondence
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  correspondenceInfo
}, dispatch);

export default (withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CorrespondenceEditGeneralInformationModal)
));
