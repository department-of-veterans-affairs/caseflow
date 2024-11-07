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
import { connect } from 'react-redux';
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

  // state variables for editable portions of the form that can be passed to child components
  const [notes, setNotes] = useState(props.correspondence.notes);
  const [veteranFileNumber, setVeteranFileNumber] = useState(props.correspondence.veteranFileNumber);
  const [correspondenceTypeId, setCorrespondenceTypeId] = useState(
    props.correspondence.correspondence_type_id
  );
  const [vaDor, setVaDor] = useState(moment.utc((props.correspondence.vaDateOfReceipt)).format('YYYY-MM-DD'));
  const [disableButton, setDisableButton] = useState(false);
  const [disableSaveButton, setDisableSaveButton] = useState(true);
  const [isReturnToQueue, setIsReturnToQueue] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [packageActionModal, setPackageActionModal] = useState(null);
  const [errorMessage, setErrorMessage] = useState('');
  const [selectedId, setSelectedId] = useState(0);
  const [isReadOnly, setIsReadOnly] = useState(false);
  const [isReassignPackage, setIsReassignPackage] = useState(false);
  const [corrTypeSelected, setCorrTypeSelected] = useState(true);
  const [blockingTaskId, setBlockingTaskId] = useState({
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
      setBlockingTaskId(assignedRemoveTask.id);
    }

    // Return true if a removePackageTask that is currently assigned is found, else false
    return (typeof assignedRemoveTask !== 'undefined');
  };

  // When a reassign package task is active and pending review, the page is read-only
  const hasAssignedReassignPackageTask = (tasks) => {
    const assignedReassignTask = tasks.find((task) => task.status === 'assigned' &&
          task.type === 'ReassignPackageTask');

    if (assignedReassignTask) {
      setBlockingTaskId(assignedReassignTask.id);
    }

    // Return true if a reassignPackageTask that is currently assigned is found, else false
    return (
      (typeof assignedReassignTask !== 'undefined')
    );
  };

  useEffect(() => {
    // Check for eFolder upload failure
    if (props.hasEfolderFailedTask) {
      setBannerInformation({
        title: CORRESPONDENCE_DOC_UPLOAD_FAILED_HEADER,
        message: CORRESPONDENCE_DOC_UPLOAD_FAILED_MESSAGE,
        bannerType: 'error'
      });
    }

    if (isPageReadOnly(props.correspondence.correspondence_tasks)) {
      setBannerInformation({
        title: CORRESPONDENCE_READONLY_BANNER_HEADER,
        message: CORRESPONDENCE_READONLY_SUPERVISOR_BANNER_MESSAGE,
        bannerType: 'info'
      });
      setIsReadOnly(true);
    }

    if (hasAssignedReassignPackageTask(props.correspondence.correspondence_tasks)) {
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
      const redirectUrl = props.userIsInboundOpsSupervisor ? '/queue/correspondence/team' : '/queue/correspondence';

      window.location.href = redirectUrl;
    }
  };

  const handlePackageActionModal = (value) => {
    setPackageActionModal(value);
  };

  const handleReview = () => {
    history.push('/queue/correspondence');
  };

  // used to validate there are no non-null values (notes can be null)
  const nullValuesPresent = () => {
    return !veteranFileNumber || !correspondenceTypeId || !vaDor;
  };

  const intakeAppeal = async () => {
    props.setFileNumberSearch(veteranFileNumber);
    try {
      await props.doFileNumberSearch('appeal', veteranFileNumber, true);
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

  // check for in-flight changes to disable the button
  useEffect(() => {
    // disable create record button if save button is enabled or null values exist
    setDisableButton(!disableSaveButton || nullValuesPresent());
    setErrorMessage('');
  }, [disableSaveButton]);

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
            blockingTaskId={blockingTaskId}
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
              correspondence={props.correspondence}
            />
          }
          <ReviewForm
            {...{
              disableButton,
              setDisableButton,
              disableSaveButton,
              setDisableSaveButton,
              setIsReturnToQueue,
              showModal,
              handleModalClose,
              handleReview,
              errorMessage,
              setErrorMessage,
              isReadOnly,
              corrTypeSelected,
              setCorrTypeSelected,
              notes,
              setNotes,
              veteranFileNumber,
              setVeteranFileNumber,
              correspondenceTypeId,
              setCorrespondenceTypeId,
              vaDor,
              setVaDor
            }}
            {...props}
            userIsInboundOpsSupervisor={props.userIsInboundOpsSupervisor}
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
            { (props.correspondence.nod && !isReadOnly) && (
              <span className="correspondence-button-wrapper">
                <Button
                  name="Intake appeal"
                  classNames={['usa-button-secondary', 'correspondence-intake-appeal-button']}
                  onClick={intakeAppeal}
                />
              </span>
            )}
            <span>
              <a href={intakeLink}>
                <Button
                  name="Create record"
                  classNames={['usa-button-primary']}
                  onClick={intakeLink}
                  disabled={disableButton}
                />
              </a>
            </span>
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
  setFileNumberSearch: PropTypes.func,
  doFileNumberSearch: PropTypes.func,
  userIsInboundOpsSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  createRecordIsReadOnly: PropTypes.string,
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  packageDocumentType: state.reviewPackage.packageDocumentType,
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
