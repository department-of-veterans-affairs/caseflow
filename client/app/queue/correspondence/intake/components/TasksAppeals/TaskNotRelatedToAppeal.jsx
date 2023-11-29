import React, { useCallback, useEffect, useState } from 'react';
import TextareaField from '../../../../../components/TextareaField';
import CheckboxModal from '../CheckboxModal';
import ReactSelectDropdown from '../../../../../components/ReactSelectDropdown';
import Button from '../../../../../components/Button';
import PropTypes from 'prop-types';
import { shallowEqual, useSelector } from 'react-redux';

const dropdownOptions = [
  { value: 'CAVC Correspondence', label: 'CAVC Correspondence' },
  { value: 'Congressional interest', label: 'Congressional interest' },
  { value: 'Death certificate', label: 'Death certificate' },
  { value: 'FOIA request', label: 'FOIA request' },
  { value: 'Other motion', label: 'Other motion' },
  { value: 'Power of attorney-related', label: 'Power of attorney-related' },
  { value: 'Privacy act request', label: 'Privacy act request' },
  { value: 'Privacy complaint', label: 'Privacy complaint' },
  { value: 'Status inquiry', label: 'Status inquiry' }
];

const autotextOptions = ['Address updated in VACOLS',
  'Decision sent to Senator or Congressman mm/dd/yy',
  'Interest noted in telephone call of mm/dd/yy',
  'Interest noted in evidence file regarding current appeal',
  'Email - responded via email on mm/dd/yy',
  'Email - written response req; confirmed receipt via email to Congress office on mm/dd/yy',
  'Possible motion pursuant to BVA decision dated mm/dd/yy',
  'Motion pursuant to BVA decision dated mm/dd/yy',
  'Statement in support of appeal by appellant',
  'Statement in support of appeal by rep',
  'Medical evidence X-Rays submitted or referred by',
  'Medical evidence clinical reports submitted or referred by',
  'Medical evidence examination reports submitted or referred by',
  'Medical evidence progress notes submitted or referred by',
  "Medical evidence physician's medical statement submitted or referred by",
  'C&P exam report',
  'Consent form (specify)',
  'Withdrawal of issues',
  'Response to BVA solicitation letter dated mm/dd/yy',
  'VAF 9 (specify)'];

const TaskNotRelatedToAppeal = (props) => {
  const task = useSelector((state) => state.intakeCorrespondence.unrelatedTasks.find((uTasks) => {
    return uTasks.id === props.taskId;
  }), shallowEqual);
  const [type, setType] = useState('');
  const [content, setContent] = useState('');
  const [modalVisible, setModalVisible] = useState(false);

  useEffect(() => {
    const canContinue = (content !== '') && (type !== '');

    props.setUnrelatedTasksCanContinue(canContinue);
  }, [content, type]);

  const unrelatedTasks = useSelector((state) => state.intakeCorrespondence.unrelatedTasks);

  // up to 2 other motion tasks can be created in the workflow
  const filterTaskOptions = () => {
    let otherMotionCount = 0;
    const filteredTaskNames = unrelatedTasks.map((unrelatedTask) => {
      if (unrelatedTask.type === 'Other motion') {
        // eslint-disable-next-line no-plusplus
        otherMotionCount++;
      }

      return unrelatedTask.type;
    });

    return dropdownOptions.filter((value) => {
      // only filter 'other motion' if there are 2 other motion tasks already created
      if (value.value === 'Other motion' && otherMotionCount < 2) {
        return true;
      }

      return !filteredTaskNames.includes(value.value);
    });
  };

  const updateTaskContent = useCallback((newContent) => {
    const newTask = { id: task.id, type: task.type, content: newContent };

    setContent(newContent);

    props.taskUpdatedCallback(newTask);
  }, [task, content]);

  const updateTaskType = useCallback((newType) => {
    const newTask = { id: task.id, type: newType.value, content: task.content };

    setType(newType.value);

    props.taskUpdatedCallback(newTask);
  }, [task, type]);

  const handleModalToggle = () => {
    setModalVisible(!modalVisible);
  };

  const handleAutotext = (autoTextValues) => {
    let autoTextOutput = '';

    if (autoTextValues.length > 0) {
      autoTextValues.forEach((id) => {
        autoTextOutput += `${autotextOptions[id] }\n`;
      });
    }
    updateTaskContent(autoTextOutput);
    handleModalToggle();
  };

  return (
    <div key={task.id} style={{ display: 'block', marginRight: '2rem' }}>
      {modalVisible && <CheckboxModal
        checkboxData={autotextOptions}
        toggleModal={handleModalToggle}
        closeHandler={handleModalToggle}
        handleAccept={handleAutotext}
      />}
      <div className="gray-border"
        style={
          { display: 'block', padding: '2rem 2rem', marginLeft: '3rem', marginBottom: '3rem', width: '50rem' }
        }>
        <div
          style={
            { width: '45rem' }
          }
        >
          <div id="reactSelectContainer">
            <ReactSelectDropdown
              options={filterTaskOptions()}
              defaultValue={dropdownOptions[task.type]}
              label="Task"
              style={{ width: '50rem' }}
              onChangeMethod={(selectedOption) => updateTaskType(selectedOption)}
              className="date-filter-type-dropdown"
            />
          </div>
          <div style={{ padding: '1.5rem' }} />
          <TextareaField
            name="content"
            label="Provide context and instruction on this task"
            value={task.content}
            onChange={updateTaskContent}
          />
          <Button
            id="addAutotext"
            name="Add"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            classNames={['cf-btn-link', 'cf-left-side']}
            onClick={handleModalToggle}
          >
            Add autotext
          </Button>
          <Button
            name="Remove"
            styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
            onClick={() => props.removeTask(task.id)}
            classNames={['cf-btn-link', 'cf-right-side']}
          >
            <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
          </Button>
        </div>
      </div>
    </div>
  );
};

TaskNotRelatedToAppeal.propTypes = {
  removeTask: PropTypes.func.isRequired,
  taskId: PropTypes.number.isRequired,
  taskUpdatedCallback: PropTypes.func.isRequired,
  setUnrelatedTasksCanContinue: PropTypes.func.isRequired
};

export default TaskNotRelatedToAppeal;
