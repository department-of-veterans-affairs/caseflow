import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useEffect, useState } from 'react';
import { useHistory } from 'react-router';
import ReviewPackageData from './ReviewPackageData';
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
    default_select_value: null
  });
  const [apiResponse, setApiResponse] = useState(null);
  const [disableButton, setDisableButton] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [packageActionModal, setPackageActionModal] = useState(null);
  const [errorMessage, setErrorMessage] = useState('');
  const [selectedId, setSelectedId] = useState(0);
  const [isReadOnly, setIsReadOnly] = useState(false);
  const [isReassignPackage, setIsReassignPackage] = useState(false);
  const [isEfolderUploadFailedTask, setIsEfolderUploadFailedTask] = useState(true);
  const [reviewPackageDetails, setReviewPackageDetails] = useState({
    veteranName: '',
    taskId: [],
  });

  // Banner Information takes in the following object:
  // {  title: ,  message: ,  bannerType: }
  const [bannerInformation, setBannerInformation] = useState(null);

  const fetchData = async () => {
    const correspondence = props;
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

    const hasEfolderUploadTask = (tasks) => {
      const existEfolderUploadTask = tasks.find((task) => task.status === 'in_progress' &&
      task.type === 'EfolderUploadFailedTask');

      if (existEfolderUploadTask) {
        setIsEfolderUploadFailedTask(false);
      }
    };

    try {
      const response = await ApiUtil.get(
        `/queue/correspondence/${correspondence.correspondence_uuid}`
      );

      setApiResponse(response.body.general_information);
      const data = response.body.general_information;

      hasEfolderUploadTask(data.correspondence_tasks);

      if (response.body.efolder_upload_failed_before.length > 0) {
        setBannerInformation({
          title: CORRESPONDENCE_DOC_UPLOAD_FAILED_HEADER,
          message: CORRESPONDENCE_DOC_UPLOAD_FAILED_MESSAGE,
          bannerType: 'error'
        });
      }

      setReviewDetails({
        veteran_name: data.veteran_name || {},
        dropdown_values: data.correspondence_types || [],
        correspondence_type_id: data.correspondence_type_id
      });

      setReviewPackageDetails((prev) => {
        return { ...prev, veteranName: `${data.veteran_name.first_name} ${data.veteran_name.last_name}` };
      }
      );

      setEditableData({
        notes: data.notes,
        veteran_file_number: data.file_number,
        default_select_value: data.correspondence_type_id,
      });

      if (isPageReadOnly(data.correspondence_tasks)) {
        setBannerInformation({
          title: CORRESPONDENCE_READONLY_BANNER_HEADER,
          message: CORRESPONDENCE_READONLY_SUPERVISOR_BANNER_MESSAGE,
          bannerType: 'info'
        });
        setIsReadOnly(true);
      }

      if (hasAssignedReassignPackageTask(data.correspondence_tasks)) {
        setBannerInformation({
          title: CORRESPONDENCE_READONLY_BANNER_HEADER,
          message: CORRESPONDENCE_READONLY_BANNER_MESSAGE,
          bannerType: 'info'
        });
        setIsReadOnly(true);
        setIsReassignPackage(true);
      }
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleModalClose = () => {
    if (disableButton) {
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
    const notesChanged = editableData.notes !== apiResponse.notes;
    const fileNumberChanged = editableData.veteran_file_number !== apiResponse.file_number;
    const selectValueChanged = editableData.default_select_value !== apiResponse.correspondence_type_id;

    return notesChanged || fileNumberChanged || selectValueChanged;
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
            efolder={isEfolderUploadFailedTask}
            handlePackageActionModal={handlePackageActionModal}
            correspondence={props.correspondence}
            packageActionModal={packageActionModal}
            isReadOnly={isReadOnly}
            isReassignPackage={isReassignPackage}
            mailTeamUsers={props.mailTeamUsers}
            userIsCorrespondenceSupervisor={props.userIsCorrespondenceSupervisor}
            isInboundOpsSuperuser={props.isInboundOpsSuperuser}
          />
          <ReviewPackageData
            correspondence={props.correspondence}
            packageDocumentType={props.packageDocumentType}
            isReadOnly={isReadOnly}
          />
          {packageActionModal &&
            <PackageActionModal
              packageActionModal={packageActionModal}
              closeHandler={handlePackageActionModal}
            />
          }
          <ReviewForm
            {...{
              reviewDetails,
              setReviewDetails,
              editableData,
              setEditableData,
              disableButton,
              setDisableButton,
              fetchData,
              showModal,
              handleModalClose,
              handleReview,
              errorMessage,
              setErrorMessage,
              isReadOnly
            }}
            {...props}
          />
          <CmpDocuments
            documents={props.correspondenceDocuments}
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
            { (props.packageDocumentType.name === '10182') && (
              <Button
                name="Intake appeal"
                classNames={['usa-button-secondary', 'correspondence-intake-appeal-button']}
                onClick={intakeAppeal}
                disabled={disableButton || isReadOnly}
              />
            )}
            <a href={intakeLink}>
              <Button
                name="Create record"
                classNames={['usa-button-primary']}
                onClick={intakeLink}
                disabled={disableButton || isReadOnly}
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
  mailTeamUsers: PropTypes.array,
  correspondence: PropTypes.object,
  correspondenceDocuments: PropTypes.arrayOf(PropTypes.object),
  packageDocumentType: PropTypes.object,
  veteranInformation: PropTypes.object,
  setFileNumberSearch: PropTypes.func,
  doFileNumberSearch: PropTypes.func,
  userIsCorrespondenceSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  correspondenceDocuments: state.reviewPackage.correspondenceDocuments,
  packageDocumentType: state.reviewPackage.packageDocumentType,
  veteranInformation: state.reviewPackage.veteranInformation,
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
