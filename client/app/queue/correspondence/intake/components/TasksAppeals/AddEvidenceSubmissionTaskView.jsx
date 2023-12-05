import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import TextareaField from '../../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Checkbox from '../../../../../components/Checkbox';
import { setWaivedEvidenceTasks } from '../../../correspondenceReducer/correspondenceActions';
import PropTypes from 'prop-types';

const AddEvidenceSubmissionTaskView = (props) => {

  // Determine if the appeal is an "evidence submission"
  const isEvidenceSubmission = props.docketName === 'evidence_submission';

  const dropdownOptions = [
    { value: 'evidence_submission', label: 'Evidence Window Submission Task', isDisabled: isEvidenceSubmission },
  ];

  const defaultValue = isEvidenceSubmission ? dropdownOptions[0] : null;
  const [isWaiveCheckboxSelected, setWaiveCheckboxSelected] = useState(false);
  const [waiveReason, setWaiveReason] = useState('');
  const [waivedEvidenceTasks, setWaivedNewEvidenceTasks] =
       useState(useSelector((state) => state.intakeCorrespondence.waivedEvidenceTasks));

  const dispatch = useDispatch();

  const handleCheckboxChange = () => {
    setWaiveCheckboxSelected(!isWaiveCheckboxSelected);

    if (!isWaiveCheckboxSelected) {
      setWaiveReason('');
    }

    const canContinue = isWaiveCheckboxSelected && Boolean(waiveReason.trim());
    const newTask = { id: props.task, content: waiveReason, isChecked: !isWaiveCheckboxSelected };

    // Dispatch the action with the updated tasks
    setWaivedNewEvidenceTasks([...waivedEvidenceTasks, newTask]);
    // dispatch(setWaivedEvidenceTasks(newTask));

    props.setRelatedTasksCanContinue(canContinue);
  };

  const handleReasonChange = (event) => {
    setWaiveReason(event);
  };

  useEffect(() => {
    // If user has selected appeals, enable continue
    if (waiveReason !== '' && isWaiveCheckboxSelected) {
      props.setRelatedTasksCanContinue(true);
    } else {
      props.setRelatedTasksCanContinue(false);
    }
  }, [waiveReason]);

  useEffect(() => {
    dispatch(setWaivedEvidenceTasks(waivedEvidenceTasks));
  }, [waivedEvidenceTasks]);

  return (
    <div key={props.docketName} style={{ display: 'block', marginRight: '2rem' }}>
      <div
        className="gray-border"
        style={{
          display: 'block',
          padding: '2rem 2rem',
          marginLeft: '3rem',
          marginBottom: '3rem',
          width: '50rem'
        }}
      >
        <div
          style={{
            width: '45rem',
          }}
        >
          <div id="reactSelectContainer">
            {/* Pass the options to the ReactSelectDropdown */}
            <ReactSelectDropdown options={dropdownOptions}
              label="Task"
              defaultValue={defaultValue}
              disabled={isEvidenceSubmission} />
          </div>
          <div style={{ padding: '1.5rem' }} />
          <TextareaField
            name="content"
            label="Provide context and instruction on this task"
            disabled={isEvidenceSubmission}
          />
          <Checkbox
            name="waive"
            defaultValue={isWaiveCheckboxSelected}
            label="Waive Evidence Window"
            onChange={handleCheckboxChange} />
          {isWaiveCheckboxSelected && (
            <TextareaField
              name="waiveReason"
              label="Provide a reason for the waiver"
              onChange={handleReasonChange}
            />
          )}
        </div>
      </div>
    </div>
  );
};

AddEvidenceSubmissionTaskView.propTypes = {
  task: PropTypes.array.isRequired,
  docketName: PropTypes.string.isRequired,
  setRelatedTasksCanContinue: PropTypes.func.isRequired,
};

export default AddEvidenceSubmissionTaskView;
