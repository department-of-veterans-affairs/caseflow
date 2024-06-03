import React, { useState, useEffect } from 'react';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';
import PropTypes from 'prop-types';
import AddCorrespondenceView from './AddCorrespondence/AddCorrespondenceView';
import { AddTasksAppealsView } from './TasksAppeals/AddTasksAppealsView';
import { connect, useDispatch, useSelector } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  loadSavedIntake,
  setUnrelatedTasks,
  saveCurrentIntake,
  setErrorBanner
} from '../../correspondenceReducer/correspondenceActions';
import { useHistory } from 'react-router-dom';
import { ConfirmCorrespondenceView } from './ConfirmCorrespondence/ConfirmCorrespondenceView';
import { SubmitCorrespondenceModal } from './ConfirmCorrespondence/SubmitCorrespondenceModal';
import Alert from 'app/components/Alert';
import {
  CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TITLE,
  CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TEXT
} from '../../../../../COPY';
import ReturnToQueueModal from './ReturnToQueueModal';
import ApiUtil from '../../../../util/ApiUtil';

const progressBarSections = [
  {
    title: '1. Add Related Correspondence',
    step: 1
  },
  {
    title: '2. Review Tasks & Appeals',
    step: 2
  },
  {
    title: '3. Confirm',
    step: 3
  },
];

export const CorrespondenceIntake = (props) => {
  const dispatch = useDispatch();
  const intakeCorrespondence = useSelector((state) => state.intakeCorrespondence);
  const showErrorBanner = useSelector((state) => state.intakeCorrespondence.showErrorBanner);
  const [currentStep, setCurrentStep] = useState(1);
  const [isContinueEnabled, setContinueEnabled] = useState(true);
  const [addTasksVisible, setAddTasksVisible] = useState(false);
  const [returnToQueueModal, setReturnToQueueModal] = useState(false);
  const [submitCorrespondenceModalVisible, setSubmitCorrespondenceModalVisible] = useState(false);
  const history = useHistory();

  const handleBannerState = (bannerState) => {
    dispatch(setErrorBanner(bannerState));
  };

  const exportStoredata = {
    correspondence_uuid: props.correspondence_uuid,
    current_step: currentStep,
    redux_store: intakeCorrespondence
  };

  const handleContinueStatusChange = (isEnabled) => {
    setContinueEnabled(isEnabled);
  };

  const handleCheckboxChange = (isSelected) => {
    setContinueEnabled(isSelected);
  };

  const nextStep = () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
      window.scrollTo(0, 0);
      history.replace({ hash: '' });
    }
  };

  const handleContinueAfterBack = () => {
    setContinueEnabled(true);
  };

  const redirectToPage = (userAction) => {
    const newUrl = new URL(window.location.href);
    const searchParams = new URLSearchParams(newUrl.search);

    // Encode and set the query parameters
    searchParams.set('correspondence_uuid', encodeURIComponent(exportStoredata.correspondence_uuid));
    searchParams.set('userAction', encodeURIComponent(userAction));
    searchParams.set('tab', encodeURIComponent('correspondence_unassigned'));
    searchParams.set('page', encodeURIComponent('1'));

    // Construct the new URL with encoded query parameters
    newUrl.search = searchParams.toString();
    newUrl.pathname = props.isInboundOpsSupervisor ? '/queue/correspondence/team' : '/queue/correspondence';
    window.location.href = newUrl.href;
  };

  const handleContinueIntakeLater = () => {
    props.saveCurrentIntake(intakeCorrespondence, exportStoredata, () => {
      redirectToPage('continue_later');
    });

  };

  const handleCancelIntake = () => {
    ApiUtil.post(`/queue/correspondence/${exportStoredata.correspondence_uuid}/cancel_intake`, { exportStoredata }).
      then((response) => {
        if (!response.ok) {
          console.error(response);
        }
        redirectToPage('cancel_intake');

      }).
      catch((err) => {
        console.error(new Error(`Problem with GET ${intakeCorrespondence} ${err}`));
      });
  };

  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
      handleContinueAfterBack();
      window.scrollTo(0, 0);
      history.replace({ hash: '' });
    }
  };

  const sections = progressBarSections.map(({ title, step }) => ({
    title,
    current: (step === currentStep)
  }),
  );

  useEffect(() => {
    if (currentStep !== 1) {
      props.saveCurrentIntake(intakeCorrespondence, exportStoredata);
    }
  }, [currentStep]);

  useEffect(() => {
    // load previous correspondence intake from database (if any)
    if (props.reduxStore !== null) {
      setCurrentStep(3);
      props.loadSavedIntake(props.reduxStore);
    }
  }, []);

  return <div>
    { showErrorBanner &&
      <Alert title={CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TITLE} type="error">
        {CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TEXT}
      </Alert>
    }
    <ProgressBar
      sections={sections}
      classNames={['cf-progress-bar', 'cf-', 'progress-bar-styling']} />
    {currentStep === 1 &&
      <AddCorrespondenceView
        priorMail={props.priorMail}
        correspondenceUuid={props.correspondence_uuid}
        onContinueStatusChange={handleContinueStatusChange}
        onCheckboxChange={handleCheckboxChange}
        isContinueEnabled={isContinueEnabled}
      />
    }
    {currentStep === 2 &&
      <AddTasksAppealsView
        addTasksVisible={addTasksVisible}
        setAddTasksVisible={setAddTasksVisible}
        disableContinue={handleContinueStatusChange}
        unrelatedTasks={props.unrelatedTasks}
        setUnrelatedTasks={props.setUnrelatedTasks}
        correspondence={props.correspondence}
        onContinueStatusChange={handleContinueStatusChange}
        autoTexts={props.autoTexts}
      />
    }
    {currentStep === 3 &&
      <div>
        <ConfirmCorrespondenceView
          correspondence={props.correspondence}
          mailTasks={props.mailTasks}
          goToStep={setCurrentStep}
          toggledCorrespondences={props.toggledCorrespondences}
          selectedCorrespondences={props.priorMail.filter((correspondence) =>
            props.toggledCorrespondences.indexOf(String(correspondence.uuid)) !== -1)}
        />
      </div>
    }
    <div className="margin-top-for-add-task-view">
      {returnToQueueModal &&
        <ReturnToQueueModal
          onCancel={() => setReturnToQueueModal(false)}
          handleContinueIntakeLater={handleContinueIntakeLater}
          handleCancelIntake={handleCancelIntake}
        />
      }
      <Button
        name="Return to queue"
        styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
        classNames={['cf-btn-link', 'cf-left-side']}
        onClick={() => setReturnToQueueModal(true)} />
      {currentStep < 3 &&
      <Button
        type="button"
        onClick={nextStep}
        name="continue"
        classNames={['cf-right-side']} disabled={!isContinueEnabled}>
          Continue
      </Button>}
      {currentStep === 3 &&
      <Button
        type="button"
        onClick={() => setSubmitCorrespondenceModalVisible(true)}
        name="Submit"
        classNames={['cf-right-side']}>
          Submit
      </Button>}
      {currentStep > 1 &&
      <Button
        type="button"
        onClick={prevStep}
        name="back-button"
        styling={{ style: { marginRight: '2rem' } }}
        classNames={['usa-button-secondary', 'cf-right-side', 'usa-back-button']}>
          Back
      </Button>}
      {currentStep === 3 && submitCorrespondenceModalVisible &&
        <SubmitCorrespondenceModal
          correspondence={props.correspondence}
          setSubmitCorrespondenceModalVisible={setSubmitCorrespondenceModalVisible}
          setErrorBannerVisible={handleBannerState}
        />
      }
    </div>
  </div>;
};

CorrespondenceIntake.propTypes = {
  correspondence_uuid: PropTypes.string,
  correspondence: PropTypes.object,
  toggledCorrespondences: PropTypes.array,
  priorMail: PropTypes.array,
  unrelatedTasks: PropTypes.arrayOf(Object),
  setUnrelatedTasks: PropTypes.func,
  mailTasks: PropTypes.arrayOf(PropTypes.string),
  autoTexts: PropTypes.arrayOf(PropTypes.string),
  reduxStore: PropTypes.object,
  isInboundOpsSupervisor: PropTypes.bool,
  loadSavedIntake: PropTypes.func,
  saveCurrentIntake: PropTypes.func
};

const mapStateToProps = (state) => ({
  unrelatedTasks: state.intakeCorrespondence.unrelatedTasks,
  mailTasks: state.intakeCorrespondence.mailTasks,
  toggledCorrespondences: state.intakeCorrespondence.relatedCorrespondences
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setUnrelatedTasks,
    loadSavedIntake,
    saveCurrentIntake
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceIntake);
