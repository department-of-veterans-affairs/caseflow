
import React from 'react';
import Modal from 'app/components/Modal';
import COPY from 'app/../COPY';
import TextField from 'app/components/TextField';
import TextareaField from 'app/components/TextareaField';
import Button from 'app/components/Button';
import PropTypes from 'prop-types';

import { useSelector } from 'react-redux';

import {
  REPORT_TYPE_OPTIONS,
  RADIO_EVENT_TYPE_OPTIONS,
  SPECIFIC_EVENT_OPTIONS,
  SPECIFIC_STATUS_OPTIONS,
  RADIO_STATUS_OPTIONS

} from 'constants/REPORT_TYPE_CONSTANTS';

export const SaveSearchModal = (props) => {
  const { setShowModal } = props;
  const saveSearchParams = useSelector((state) => state.savedSearch.saveUserSearch);
  const handleSaveSearch = () => {
    alert(1);
  };

  const handleCancel = () => {
    setShowModal(false);
  };

   const reportTypeEventValue = RADIO_EVENT_TYPE_OPTIONS.
    find((reportTypeOptions) => reportTypeOptions.value === saveSearchParams.radioEventAction)?.displayText;

  const reportTypeStatusValue = RADIO_STATUS_OPTIONS.
    find((reportTypeOptions) => reportTypeOptions.value === saveSearchParams.radioStatus)?.displayText;

  const reportTypeTitle = REPORT_TYPE_OPTIONS.
    find((reportTypelabel) => reportTypelabel.value === saveSearchParams.reportType).label;

  // this method needs some refactoring
  const generateEventTypeList = () => {
    if (saveSearchParams?.radioEventAction === 'all_events_action') {
      return '';
    }
    const userSelectedEvent = Object.keys(saveSearchParams.specificEventType);
    const flattenEventList = Object.values(SPECIFIC_EVENT_OPTIONS[0]).flatMap((obj) => Object.values(obj));
    const filteredEvent = flattenEventList.filter((obj) => userSelectedEvent.includes(obj.id));

    const eventList = filteredEvent.map((obj) => obj.label).join(', ');

    return ` - ${eventList}`;
  };

  const generateStatusList = () => {
    if (saveSearchParams?.radioStatus === 'all_statuses') {
      return '';
    }
    const userSelectedStatus = Object.keys(saveSearchParams.specificStatus);
    const filteredStatus = SPECIFIC_STATUS_OPTIONS.filter((obj) => userSelectedStatus.includes(obj.id));

    const statusList = filteredStatus.map((obj) => obj.label).join(', ');

    return ` - ${statusList}`;

  };

  const ReportTypeFragment = () => {
    return <>
      <li>
        <b>{reportTypeTitle}: </b>
        {saveSearchParams.reportType === 'event_type_action' ?
          reportTypeEventValue + generateEventTypeList() :
          reportTypeStatusValue + generateStatusList()}
      </li>
    </>;
  };

  // const TimingSpecification = () => {
  //   return <></>;
  // };

  // const DaysWaiting;
  // const decisionReviewType;
  // const issueType;
  // const issueDisposition;
  // const personnel;
  // const facility;

  return (
    <Modal
      title={COPY.SAVE_YOUR_SEARCH_TITLE}
      closeHandler={() => setShowModal(false)}
      confirmButton={<Button id="save-search" onClick={handleSaveSearch}>Save search</Button>}
      cancelButton={
        <Button
          id="cancel"
          classNames={['cf-modal-link', 'cf-btn-link']}
          onClick={handleCancel}>
            Cancel
        </Button>
      }
    >
      <b>{COPY.SEARCH_PARAMETERS}</b>
      <p>{JSON.stringify(saveSearchParams)}</p>

      {/* <li><b>{reportTypeTitle}:</b> {reportTypeStatusValue} {specificStatusType()}</li>
       */}
       <p>{ReportTypeFragment()}</p>
      <TextField
        name="Name this search (Max 50 characters)"
        maxLength={50}
      />
      <TextareaField
        name="Description of search (Max 100 characters)"
        optional
        maxLength={100}
      />
    </Modal>);
};

SaveSearchModal.propTypes = {
  setShowModal: PropTypes.func.isRequired
};

export default SaveSearchModal;
