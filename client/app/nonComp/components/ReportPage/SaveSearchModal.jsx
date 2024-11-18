import React, { useState } from 'react';
import Modal from 'app/components/Modal';
import COPY from 'app/../COPY';
import TextField from 'app/components/TextField';
import TextareaField from 'app/components/TextareaField';
import Button from 'app/components/Button';
import PropTypes from 'prop-types';
import moment from 'moment';

import { useSelector, useDispatch } from 'react-redux';
import { createSearch } from 'app/nonComp/actions/savedSearchSlice';

import {
  REPORT_TYPE_OPTIONS,
  RADIO_EVENT_TYPE_OPTIONS,
  SPECIFIC_EVENT_OPTIONS,
  SPECIFIC_STATUS_OPTIONS,
  RADIO_STATUS_OPTIONS,
  RADIO_STATUS_REPORT_TYPE_OPTIONS,
  TIMING_SPECIFIC_OPTIONS,
  CONDITION_DROPDOWN_LIST
} from 'constants/REPORT_TYPE_CONSTANTS';

export const SaveSearchModal = ({ setShowModal }) => {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const saveSearchParams = useSelector((state) => state.savedSearch.saveUserSearch);
  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const dispatch = useDispatch();

  const handleSave = () => {
    const data = {
      search: {
        name,
        description,
        savedSearch: saveSearchParams
      }
    };

    dispatch(createSearch({ organizationUrl: businessLineUrl, postData: data }));
    setShowModal(false);
  };

  const handleCancel = () => {
    setShowModal(false);
  };

  const reportTypeEventValue = RADIO_EVENT_TYPE_OPTIONS.
    find((reportTypeOptions) => reportTypeOptions.value === saveSearchParams.radioEventAction)?.displayText;

  const reportTypeStatusValue = RADIO_STATUS_OPTIONS.
    find((reportTypeOptions) => reportTypeOptions.value === saveSearchParams.radioStatus)?.displayText;

  const reportTypeTitle = REPORT_TYPE_OPTIONS.
    find((reportTypelabel) => reportTypelabel.value === saveSearchParams.reportType)?.label;

  const generateEventTypeList = () => {
    if (saveSearchParams?.radioEventAction === 'all_events_action') {
      return '';
    }
    const userSelectedEvent = Object.keys(saveSearchParams.specificEventType).
      filter((key) => saveSearchParams.specificEventType[key] === true);

    const flattenEventList = Object.values(SPECIFIC_EVENT_OPTIONS[0]).flatMap((obj) => Object.values(obj));
    const filteredEvent = flattenEventList.filter((obj) => userSelectedEvent.includes(obj.id));

    const eventList = filteredEvent.map((obj) => obj.label).join(', ');

    return ` - ${eventList}`;
  };

  const generateStatusList = () => {
    if (saveSearchParams?.radioStatus === 'all_statuses') {
      return '';
    }
    const userSelectedStatus = Object.keys(saveSearchParams.specificStatus).
      filter((key) => saveSearchParams.specificStatus[key] === true);

    const filteredStatus = SPECIFIC_STATUS_OPTIONS.filter((obj) => userSelectedStatus.includes(obj.id));

    const statusList = filteredStatus.map((obj) => obj.label).join(', ');

    return ` - ${statusList}`;

  };

  const reportTypeFragment = () => {
    return <>
      <li>
        <b>{reportTypeTitle}: </b>
        {saveSearchParams.reportType === 'event_type_action' ?
          reportTypeEventValue + generateEventTypeList() :
          reportTypeStatusValue + generateStatusList()}
      </li>
    </>;
  };

  const typeOfStatusReportFragment = () => {
    if (saveSearchParams.reportType === 'event_type_action') {
      return '';
    }

    const typeOfStatusReportTitle = 'Type of Status Report:';
    const typeOfStatusReportValue = RADIO_STATUS_REPORT_TYPE_OPTIONS.
      find((statusReportLabel) => statusReportLabel.value === saveSearchParams.radioStatusReportType).displayText;

    return <>
      <li>
        <b>{typeOfStatusReportTitle} </b>
        {typeOfStatusReportValue}
      </li>
    </>;
  };

  const timingSpecificationFragment = () => {
    const timingRange = saveSearchParams?.timing?.range;

    if (saveSearchParams.reportType === 'status' || timingRange === null) {
      return '';
    }

    const timingSpecificationTitle = 'Timing Specifications: ';

    const startDate = moment(saveSearchParams?.timing?.startDate).format('MM/DD/YYYY');
    const endDate = moment(saveSearchParams?.timing?.endDate).format('MM/DD/YYYY');
    let timingSpecificationValue;

    switch (timingRange) {
    case 'between':
      timingSpecificationValue = `Between ${startDate} to ${endDate}`;
      break;
    case 'after':
      timingSpecificationValue = `After ${startDate}`;
      break;
    case 'before':
      timingSpecificationValue = `Before ${startDate}`;
      break;
    default:
      timingSpecificationValue = TIMING_SPECIFIC_OPTIONS.
        find((timingSpec) => timingSpec.value === timingRange)?.label;
      break;
    }

    return <>
      <li>
        <b>{timingSpecificationTitle}</b>
        {timingSpecificationValue}
      </li>
    </>;
  };

  const conditionTitle = (conditionObj) => {
    return <b> {`Conditions
        ${CONDITION_DROPDOWN_LIST.find((conditionLabel) => conditionLabel.value === conditionObj.condition).label}: `
    }
    </b>;

  };

  const conditionBody = (conditionObj) => {
    const options = conditionObj.options;
    const conditionSelected = conditionObj.condition;
    const valueOne = conditionObj?.options?.valueOne;
    const valueTwo = conditionObj?.options?.valueTwo;

    const suffix = valueOne === 1 ? ' day' : ' days';

    let conditionOptionList;

    if (conditionSelected === 'daysWaiting') {
      switch (options.comparisonOperator) {
      case 'between':
        conditionOptionList = `Between ${valueOne} to ${valueTwo} days`;
        break;
      case 'lessThan':
        conditionOptionList = `Less than ${valueOne} ${suffix}`;
        break;
      case 'moreThan':
        conditionOptionList = `More than ${valueOne} ${suffix}`;
        break;
      case 'equalTo':
        conditionOptionList = `Equal to ${valueOne} ${suffix}`;
        break;
      default:
        break;
      }
    } else {
      conditionOptionList = Object.values(options)[0].map((item) => item.label).join(', ');
    }

    return <>{conditionOptionList}</>;
  };

  const conditionsFragment = () => {
    if (!Object.keys(saveSearchParams).includes('conditions')) {
      return '';
    }

    const conditionList = saveSearchParams?.conditions;

    return <>
      {
        conditionList.map((conditionObj) =>
          <li>
            {conditionTitle(conditionObj)}
            {conditionBody(conditionObj)}
          </li>
        )
      }
    </>;
  };

  const searchParameterFragment = () => {
    return <>
      <b>{COPY.SEARCH_PARAMETERS}</b>
      <ul>
        {reportTypeFragment()}
        {typeOfStatusReportFragment()}
        {timingSpecificationFragment()}
        {conditionsFragment()}
      </ul>
    </>;
  };

  const characterLimit = <i style ={{ color: '#323A45' }}> {`${50 - name.length} characters left` } </i>;

  return (
    <Modal
      title={COPY.SAVE_YOUR_SEARCH_TITLE}
      closeHandler={() => setShowModal(false)}
      confirmButton={<Button id="save-search" onClick={handleSave} disabled={!name}>Save search</Button>}
      cancelButton={
        <Button
          id="cancel"
          classNames={['cf-modal-link', 'cf-btn-link']}
          onClick={handleCancel}>
          Cancel
        </Button>
      }
    >
      {searchParameterFragment()}
      <div style={{ height: '125px' }} >
        <TextField
          name="Name this search (Max 50 characters)"
          maxLength={50}
          value={name}
          onChange={(val) => setName(val)}
          textAreaStyling={{ rows: '1' }}
          validationError={name ? characterLimit : null}
        />
      </div>
      <div style={{ height: '175px' }} >
        <TextareaField
          label="Description of search (Max 100 characters)"
          name="Description of search (Max 100 characters)"
          maxlength={100}
          optional
          value={description}
          onChange={(val) => setDescription(val)}
        />
      </div>
    </Modal>);
};

SaveSearchModal.propTypes = {
  setShowModal: PropTypes.func.isRequired
};

export default SaveSearchModal;
