import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useEffect, useState } from 'react';
import { useHistory } from 'react-router';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import ReviewForm from './ReviewForm';
import { CmpDocuments } from './CmpDocuments';
import ApiUtil from '../../../util/ApiUtil';
import PropTypes from 'prop-types';
import { setFileNumberSearch, doFileNumberSearch } from '../../../intake/actions/intake';
import { connect, useSelector } from 'react-redux';
import { bindActionCreators } from 'redux';
import PackageActionModal from '../modals/PackageActionModal';
import ReviewPackageNotificationBanner from './ReviewPackageNotificationBanner';
import moment from 'moment';
import {
  CORRESPONDENCE_READONLY_BANNER_HEADER,
  CORRESPONDENCE_READONLY_BANNER_MESSAGE,
  CORRESPONDENCE_READONLY_SUPERVISOR_BANNER_MESSAGE,
  CORRESPONDENCE_DOC_UPLOAD_FAILED_HEADER,
  CORRESPONDENCE_DOC_UPLOAD_FAILED_MESSAGE }
  from '../../../../COPY';

export const CorrespondenceReviewPackage = (props) => {
  const history = useHistory();
  const [reviewDetails, setReviewDetails] = useState({
    veteran_name: {},
    dropdown_values: [],
  });
  const [editableData, setEditableData] = useState({
    notes: '',
    veteran_file_number: '',
    default_select_value: null,
    va_date_of_receipt: '',
  });

  const stateCorrespondence = useSelector(
    (state) => state.reviewPackage.correspondence
  );
  const [displayIntakeAppeal, setDisplayIntakeAppeal] = useState(true);
  const [disableButton, setDisableButton] = useState(false);
  const [isReturnToQueue, setIsReturnToQueue] = useState(false);
  const [apiResponse, setApiResponse] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [packageActionModal, setPackageActionModal] = useState(null);
  const [errorMessage, setErrorMessage] = useState('');
  const [selectedId, setSelectedId] = useState(0);
  const [isReadOnly, setIsReadOnly] = useState(false);
  const [isReassignPackage, setIsReassignPackage] = useState(false);
  const [corrTypeSelected, setCorrTypeSelected] = useState(true);
  const [reviewPackageDetails, setReviewPackageDetails] = useState({
    veteranName: '',
    taskId: [],
  });

  // Banner Information takes in the following object:
  // {  title: ,  message: ,  bannerType: }
  const [bannerInformation, setBannerInformation] = useState(null);

  // When a remove package task is active and pending review, the page is read-only
  const isPageReadOnly = (tasks) => {
    const assignedRemoveTask = tasks.find((task) => task.status === 'assigned' && task.type === 'RemovePackageTask');

    if (assignedRemoveTask) {
      setReviewPackageDetails((prev) => {
        return { ...prev, taskId: assignedRemoveTask.id };
      }
      );
    }

    // Return true if a removePackageTask that is currently assigned is found, else false
    return (typeof assignedRemoveTask !== 'undefined');
  };

  // When a reassign package task is active and pending review, the page is read-only
  const hasAssignedReassignPackageTask = (tasks) => {
    const assignedReassignTask = tasks.find((task) => task.status === 'assigned' &&
          task.type === 'ReassignPackageTask');

    if (assignedReassignTask) {
      setReviewPackageDetails({ taskId: assignedReassignTask.id });
    }

    // Return true if a reassignPackageTask that is currently assigned is found, else false
    return (
      (typeof assignedReassignTask !== 'undefined')
    );
  };

  useEffect(() => {
    const apiResWithVADOR = moment.utc((props.correspondence.vaDateOfReceipt)).format('YYYY-MM-DD');

    setApiResponse(apiResWithVADOR);
    setDisplayIntakeAppeal(props.correspondence.display_intake_appeal);

    // Check for eFolder upload failure
    if (props.hasEfolderFailedTask) {
      setBannerInformation({
        title: CORRESPONDENCE_DOC_UPLOAD_FAILED_HEADER,
        message: CORRESPONDENCE_DOC_UPLOAD_FAILED_MESSAGE,
        bannerType: 'error'
      });
    }

    setReviewDetails({
      veteran_name: props.correspondence.veteran_name || {},
      dropdown_values: props.correspondence.correspondenceTypes || [],
      correspondence_type_id: props.correspondence.correspondence_type_id
    });
    setReviewPackageDetails((prev) => {
      return { ...prev, veteranName: `${props.correspondence.veteran_name.first_name} ${props.correspondence.veteran_name.last_name}` };
    }
    );

    setEditableData({
      notes: props.correspondence.notes,
      veteran_file_number: props.correspondence.file_number,
      default_select_value: props.correspondence.correspondence_type_id,
      va_date_of_receipt: moment.utc((props.correspondence.va_date_of_receipt)).format('YYYY-MM-DD')
    });

    if (isPageReadOnly(props.correspondence.correspondence_tasks)) {
      setBannerInformation({
        title: CORRESPONDENCE_READONLY_BANNER_HEADER,
        message: CORRESPONDENCE_READONLY_SUPERVISOR_BANNER_MESSAGE,
        bannerType: 'info'
      });
      setIsReadOnly(true);
    }

    if (hasAssignedReassignPackageTask(props.veteranInformation.correspondence_tasks)) {
      setBannerInformation({
        title: CORRESPONDENCE_READONLY_BANNER_HEADER,
        message: CORRESPONDENCE_READONLY_BANNER_MESSAGE,
        bannerType: 'info'
      });
      setIsReadOnly(true);
      setIsReassignPackage(true);
    }
  }, [props.hasEfolderFailedTask]);

  const handleModalClose = () => {
    if (isReturnToQueue) {
      setShowModal(!showModal);
    } else {
      history.goBack();
    }
  };

  const handlePackageActionModal = (value) => {
    setPackageActionModal(value);
  };

  const handleReview = () => {
    history.push('/queue/correspondence');
  };

  const isEditableDataChanged = () => {
    const notesChanged = editableData.notes !== props.correspondence.notes;
    const fileNumberChanged = editableData.veteran_file_number !== props.correspondence.veteranFileNumber;
    const selectValueChanged = editableData.default_select_value !== reviewDetails.correspondence_type_id;
    const selectDateChanged = editableData.va_date_of_receipt !== moment.utc((props.correspondence.va_date_of_receipt)).format('YYYY-MM-DD');

    return notesChanged || fileNumberChanged || selectValueChanged || selectDateChanged;
  };

  const intakeAppeal = async () => {
    props.setFileNumberSearch(editableData.veteran_file_number);
    try {
      await props.doFileNumberSearch('appeal', editableData.veteran_file_number, true);
      await ApiUtil.patch(`/queue/correspondence/${props.correspondence_uuid}/intake_update`);
      window.location.href = '/intake/review_request';
    } catch (error) {
      console.error(error);
      setBannerInformation({
        title: CORRESPONDENCE_DOC_UPLOAD_FAILED_HEADER,
        message: CORRESPONDENCE_DOC_UPLOAD_FAILED_MESSAGE,
        bannerType: 'error'
      });
    }
  };

  const intakeLink = async () => {
    const data = {
      id: props.correspondence.id
    };

    try {
      await ApiUtil.post(`/queue/correspondence/${props.correspondence_uuid}/correspondence_intake_task`, { data });
      window.location.href = `/queue/correspondence/${props.correspondence_uuid}/intake`;
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    if (apiResponse) {
      const hasChanged = isEditableDataChanged();

      setDisableButton(hasChanged);
      setErrorMessage('');
    }
  }, [editableData, apiResponse]);

  const reviewPackageData = {
    notes: props.correspondence.notes,
    veteranFullName: props.correspondence.veteranFullName,
    fileNumber: props.correspondence.file_number,
    packageDocumentType: props.correspondence.correspondenceDocuments.length &&
     props.correspondence.correspondenceDocuments[0].document_title.includes('10182') ? 'NOD' : 'Non-NOD',
    vaDor: moment.utc(props.correspondence.vaDateOfReceipt).format('YYYY-MM-DD'),
    correspondenceTypes: props.correspondenceTypes
  };

  return (
    <div>
      { bannerInformation && (
        <ReviewPackageNotificationBanner
          title={bannerInformation.title}
          message={bannerInformation.message}
          type={bannerInformation.bannerType}
        />
      )}
      <React.Fragment>
        <AppSegment filledBackground>
          <ReviewPackageCaseTitle
            reviewDetails={reviewPackageDetails}
            efolder={props.hasEfolderFailedTask}
            handlePackageActionModal={handlePackageActionModal}
            correspondence={props.correspondence}
            packageActionModal={packageActionModal}
            isReadOnly={isReadOnly}
            isReassignPackage={isReassignPackage}
            inboundOpsTeamUsers={props.inboundOpsTeamUsers}
            userIsInboundOpsSupervisor={props.userIsInboundOpsSupervisor}
            isInboundOpsSuperuser={props.isInboundOpsSuperuser}
          />

          {packageActionModal &&
            <PackageActionModal
              packageActionModal={packageActionModal}
              closeHandler={handlePackageActionModal}
            />
          }
          <ReviewForm
            {...{
              reviewPackageData,
              reviewDetails,
              setReviewDetails,
              editableData,
              setEditableData,
              disableButton,
              setDisableButton,
              setIsReturnToQueue,
              showModal,
              handleModalClose,
              handleReview,
              errorMessage,
              setErrorMessage,
              isReadOnly,
              corrTypeSelected,
              setCorrTypeSelected
            }}
            {...props}
            userIsInboundOpsSupervisor={props.userIsInboundOpsSupervisor}
            isInboundOpsSuperuser={props.isInboundOpsSuperuser}
          />
          <CmpDocuments
            documents={props.correspondence.correspondenceDocuments}
            selectedId={selectedId}
            setSelectedId={setSelectedId}
            isReadOnly={isReadOnly}
          />

        </AppSegment>
        <div className="cf-app-segment">
          <div className="cf-push-left">
            <Button
              name="Return to queue"
              classNames={['cf-btn-link']}
              onClick={handleModalClose}
            />
          </div>
          <div className="cf-push-right">
            { (displayIntakeAppeal || stateCorrespondence.nod) && (
              <Button
                name="Intake appeal"
                classNames={['usa-button-secondary', 'correspondence-intake-appeal-button']}
                onClick={intakeAppeal}
                disabled={!disableButton || isReadOnly}

              />
            )}
            <a href={intakeLink}>
              <Button
                name="Create record"
                classNames={['usa-button-primary']}
                onClick={intakeLink}
                disabled={corrTypeSelected}
              />
            </a>
          </div>
        </div>
      </React.Fragment>
    </div>
  );
};

CorrespondenceReviewPackage.propTypes = {
  correspondence_uuid: PropTypes.string,
  inboundOpsTeamUsers: PropTypes.array,
  correspondence: PropTypes.object,
  correspondenceTypes: PropTypes.array,
  hasEfolderFailedTask: PropTypes.bool,
  packageDocumentType: PropTypes.object,
  veteranInformation: PropTypes.object,
  setFileNumberSearch: PropTypes.func,
  doFileNumberSearch: PropTypes.func,
  userIsInboundOpsSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  createRecordIsReadOnly: PropTypes.string,
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  packageDocumentType: state.reviewPackage.packageDocumentType,
  veteranInformation: state.reviewPackage.veteranInformation,
  createRecordIsReadOnly: state.reviewPackage.createRecordIsReadOnly,
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setFileNumberSearch,
  doFileNumberSearch
}, dispatch);

export default
connect(
  mapStateToProps,
  mapDispatchToProps,
)(CorrespondenceReviewPackage);
