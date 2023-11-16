import React, { useState } from 'react';
import TextareaField from '../../../../components/TextareaField';
import ReactSelectDropdown from '../../../../components/ReactSelectDropdown';
import PropTypes from 'prop-types';
import Button from '../../../../components/Button';
import CheckboxModal from './CheckboxModal';

const TaskNotRelatedToAppeal = (props) => {

  const dropdownOptions = [
    { value: 0, label: 'CAVC Correspondence' },
    { value: 1, label: 'Congressional interest' },
    { value: 2, label: 'Death certificate' },
    { value: 3, label: 'FOIA request' },
    { value: 4, label: 'Other motion' },
    { value: 5, label: 'Power of attorney-related' },
    { value: 6, label: 'Privacy act request' },
    { value: 7, label: 'Privacy complaint' },
    { value: 8, label: 'Status inquiry' }
  ];

  const debugData = ['Address updated in VACOLS',
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

  const [instructionText, setInstructionText] = useState('');
  const [index] = useState(-1);
  const [modalVisible, setModalVisible] = useState(false);

  const handleChangeInstructionText = (newText) => {
    setInstructionText(newText);
    props.handleChangeTaskType(props.taskType, newText, index);
  };

  const handleModalToggle = () => {
    setModalVisible(!modalVisible);
  };

  const handleAddAutoText = (autoTextValues) => {
    let autoTextOutput = '';

    if (autoTextValues.length > 0) {
      autoTextValues.forEach((id) => {
        autoTextOutput += `${debugData[id] }\n`;
      });
    }
    handleChangeInstructionText(autoTextOutput);
    handleModalToggle();

  };

  return (
    <div key={props.key} style={{ display: 'block', marginRight: '2rem' }}>

      {modalVisible && <CheckboxModal
        checkboxData={debugData}
        toggleModal={handleModalToggle}
        closeHandler={handleModalToggle}
        addHandler={null}
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
          <ReactSelectDropdown
            options={dropdownOptions}
            defaultValue={dropdownOptions[props.taskType]}
            label="Task"
            style={{ width: '50rem' }}
            onChangeMethod={(selectedOption) =>
              props.handleChangeTaskType(selectedOption.value, instructionText, index)}
            className="date-filter-type-dropdown"
          />
          <div style={{ padding: '1.5rem' }} />
          <TextareaField
            name="Task Information"
            label="Provide context and instruction on this task"
            defaultText="Is this existing"
            value={props.taskText}
            onChange={handleChangeInstructionText}
          />
          <Button
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
            onClick={props.removeTask}
            classNames={['cf-btn-link', 'cf-right-side']} >
            <i className="fa fa-trash-o" aria-hidden="true"></i> Remove task
          </Button>
        </div>
      </div>
    </div>
  );
};

TaskNotRelatedToAppeal.propTypes = {
  removeTask: PropTypes.func,
  index: PropTypes.number,
  key: PropTypes.object,
  handleChangeTaskType: PropTypes.func,
  taskType: PropTypes.number,
  taskText: PropTypes.string
};

export default TaskNotRelatedToAppeal;
