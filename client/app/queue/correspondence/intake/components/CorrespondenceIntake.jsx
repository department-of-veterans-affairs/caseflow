import React, { useState, useEffect } from 'react';
import ProgressBar from 'app/components/ProgressBar';
import Button from '../../../../components/Button';
import PropTypes from 'prop-types';
import AddCorrespondenceView from './AddCorrespondence/AddCorrespondenceView';
import { AddTasksAppealsView } from './TasksAppeals/AddTasksAppealsView';
import { connect, useSelector } from 'react-redux';
import { bindActionCreators } from 'redux';
import { setUnrelatedTasks } from '../../correspondenceReducer/correspondenceActions';
import { useHistory, useLocation } from 'react-router-dom';
import { ConfirmCorrespondenceView } from './ConfirmCorrespondence/ConfirmCorrespondenceView';
import { SubmitCorrespondenceModal } from './ConfirmCorrespondence/SubmitCorrespondenceModal';
import Alert from 'app/components/Alert';
import ApiUtil from '../../../../util/ApiUtil';
import {
  CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TITLE,
  CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TEXT
} from '../../../../../COPY';

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
  const intakeCorrespondence = useSelector((state) => state.intakeCorrespondence);
  const [currentStep, setCurrentStep] = useState(1);
  const [isContinueEnabled, setContinueEnabled] = useState(true);
  const [addTasksVisible, setAddTasksVisible] = useState(false);
  const [submitCorrespondenceModalVisible, setSubmitCorrespondenceModalVisible] = useState(false);
  const [errorBannerVisible, setErrorBannerVisible] = useState(false);
  const { pathname, hash, key } = useLocation();
  const history = useHistory();
  // For hash routing - Add element id and which step it lives on here
  const SECTION_MAP = { 'task-not-related-to-an-appeal': 2 };

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
    const data = {
      correspondence_uuid: props.correspondence_uuid,
      current_step: currentStep,
      redux_store: intakeCorrespondence
    };

    ApiUtil.post(`/queue/correspondence/${props.correspondence_uuid}/current_step`, { data }).
      then(
        (response) => {
          if (!response.ok) {
            console.error(response);
          }
        }
      );
  }, [currentStep]);

  useEffect(() => {
    if (hash === '') {
      window.scrollTo(0, 0);
    } else {
      setTimeout(() => {
        const id = hash.replace('#', '');

        setCurrentStep(SECTION_MAP[id]);
        const element = document.getElementById(id);

        if (element) {
          element.scrollIntoView();
        }
      }, 0);
    }
  }, [pathname, hash, key]);

  return <div>
    { errorBannerVisible &&
      <Alert title={CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TITLE} type="error">
        {CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER_TEXT}
      </Alert>
    }
    <ProgressBar
      sections={sections}
      classNames={['cf-progress-bar', 'cf-']}
      styling={{ style: { marginBottom: '5rem', float: 'right' } }} />
    {currentStep === 1 &&
      <AddCorrespondenceView
        correspondenceUuid={props.correspondence_uuid}
        onContinueStatusChange={handleContinueStatusChange}
        onCheckboxChange={handleCheckboxChange}
      />
    }
    {currentStep === 2 &&
      <AddTasksAppealsView
        addTasksVisible={addTasksVisible}
        setAddTasksVisible={setAddTasksVisible}
        disableContinue={handleContinueStatusChange}
        unrelatedTasks={props.unrelatedTasks}
        setUnrelatedTasks={props.setUnrelatedTasks}
        correspondenceUuid={props.correspondence_uuid}
        onContinueStatusChange={handleContinueStatusChange}
        autoTexts={props.autoTexts}
        veteranInformation={props.veteranInformation}
      />
    }
    {currentStep === 3 &&
      <div>
        <ConfirmCorrespondenceView
          mailTasks={props.mailTasks}
          goToStep={setCurrentStep}
          toggledCorrespondences={props.toggledCorrespondences}
          selectedCorrespondences={props.correspondences.filter((currentCorrespondence) =>
            props.toggledCorrespondences.indexOf(String(currentCorrespondence.id)) !== -1)}
        />
      </div>
    }
    <div>
      <a href="/queue/correspondence">
        <Button
          name="Cancel"
          styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
          href="/queue/correspondence"
          classNames={['cf-btn-link', 'cf-left-side']} />
      </a>
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
          setSubmitCorrespondenceModalVisible={setSubmitCorrespondenceModalVisible}
          setErrorBannerVisible={setErrorBannerVisible}
        />
      }
    </div>
  </div>;
};

CorrespondenceIntake.propTypes = {
  correspondence_uuid: PropTypes.string,
  currentCorrespondence: PropTypes.object,
  veteranInformation: PropTypes.object,
  toggledCorrespondences: PropTypes.array,
  correspondences: PropTypes.array,
  unrelatedTasks: PropTypes.arrayOf(Object),
  setUnrelatedTasks: PropTypes.func,
  mailTasks: PropTypes.arrayOf(PropTypes.string),
  autoTexts: PropTypes.arrayOf(PropTypes.string)
};

const mapStateToProps = (state) => ({
  correspondences: state.intakeCorrespondence.correspondences,
  unrelatedTasks: state.intakeCorrespondence.unrelatedTasks,
  mailTasks: state.intakeCorrespondence.mailTasks,
  toggledCorrespondences: state.intakeCorrespondence.relatedCorrespondences
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setUnrelatedTasks
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceIntake);
