import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
// import { connect } from 'react-redux';
// import { bindActionCreators } from 'redux';
import TextareaField from '../../../../../components/TextareaField';
// import Checkbox from '../../../../../components/Checkbox';
import Button from '../../../../../components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import RadioField from '../../../../../components/RadioField';
import { ADD_CORRESPONDENCE_LETTER_SELECTIONS } from '../../../../constants';
// import ApiUtil from '../../../../../util/ApiUtil';

// import {
//   setResponseLetters
// } from '../../../correspondenceReducer/correspondenceActions';

export const AddLetter = (props) => {
  const onContinueStatusChange = props.onContinueStatusChange;

  const [letters, setLetters] = useState([]);
  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);
  const [customResponseWindowState, setCustomResponseWindowState] = useState(false);

  const [letterType, setLetterType] = useState('');
  const [letterTitle, setLetterTitle] = useState('');
  const [letterTitleSelector, setLetterTitleSelector] = useState();
  const [letterSub, setLetterSub] = useState();
  const [letterSubSelector, setLetterSubSelector] = useState();
  const [letterSubReason, setLetterSubReason] = useState();

  const letterTypesData = ADD_CORRESPONDENCE_LETTER_SELECTIONS.map((option) => ({ label: (option.letter_type),
    value: option.letter_type }));

  const letterTitlesData = (currentType) => {
    for (let i = 0; ADD_CORRESPONDENCE_LETTER_SELECTIONS.length; i++) {
      const option = ADD_CORRESPONDENCE_LETTER_SELECTIONS[i];

      if (option.letter_type === currentType) {
        setLetterTitleSelector(option.letter_titles.map((current) => ({
          label: (current.letter_title), value: current.letter_title
        })));

        setLetterSubSelector(option.letter_titles.map((current) => (
          current.letter_subcategories.length && current.letter_subcategories.map((sub) => (
            { label: (sub.subcategory), value: (sub.subcategory) })
          )
        )));
      }
    }
  };

  const addLetter = (index) => {
    setLetters([...letters, index]);
  };

  const changeLetterTitle = (val) => {
    setLetterType(val.value);
    letterTitlesData(val.value);
  };

  const removeLetter = (index) => {
    const restLetters = letters.filter((letter) => letter !== index);

    setLetters(restLetters);
  };

  const handleCustomWindowState = (currentOpt) => {
    if (currentOpt === 'Other') {
      setCustomResponseWindowState(true);
    } else {
      setCustomResponseWindowState(false);
    }
  };

  useEffect(() => {
    onContinueStatusChange(unrelatedTasksCanContinue);
  }, [unrelatedTasksCanContinue]);

  useEffect(() => {
    if (letters.length > 0) {
      setUnrelatedTasksCanContinue(false);
    } else {
      setUnrelatedTasksCanContinue(true);
    }
  }, [letters]);

  // useEffect(() => {
  //   let canContinue = true;

  //   // letters.forEach((letter) => {
  //   //   // canContinue = canContinue && ((letter.content !== '') && (task.type !== ''));
  //   // });

  //   setUnrelatedTasksCanContinue(canContinue);
  // }, [letters]);

  const radioOptions = [
    { displayText: '65 days',
      value: '65' },
    { displayText: 'No response window',
      value: 'no_response' },
    { displayText: 'Custom',
      value: 'Other' }
  ];

  return (
    <>
      { letters.map((letter) => (
        <div id={letter} style={{ width: '50%', display: 'inline-block' }} key={letter}>
          <NewLetter radioOptions={radioOptions}
            index={letter}
            removeLetter={removeLetter}
            customWindows={customResponseWindowState}
            handleCustomWindowState = {handleCustomWindowState}
            letterType = {letterType}
            setLetterType = {setLetterType}
            letterTitle = {letterTitle}
            setLetterTitle = {setLetterTitle}
            letterTypesData = {letterTypesData}
            letterTitlesData = {letterTitlesData}
            changeLetterTitle = {changeLetterTitle}
            letterTitleSelector = {letterTitleSelector}
            letterSub = {letterSub}
            setLetterSub = {setLetterSub}
            setLetterSubSelector ={setLetterSubSelector}
          />
        </div>
      )) }

      <div style={{ width: '80%', marginBottom: '30px' }}>
        <Button
          type="button"
          name="addLetter"
          className={['cf-left-side']}
          disabled= {!(letters.length < 3)}
          onClick={() => {
            addLetter(letters.length + 1);
          }}>
        + Add letter
        </Button>
      </div>
    </>

  );
};

AddLetter.propTypes = {
  radioOptions: PropTypes.array,
  removeLetter: PropTypes.func,
  index: PropTypes.number,
  onContinueStatusChange: PropTypes.func,
  customResponseWindowState: PropTypes.bool,
  handleCustomWindowState: PropTypes.func,
  letterTypesData: PropTypes.func,
  letterTitlesData: PropTypes.func,
  changeLetterTitle: PropTypes.func,
  letterTitleSelector: PropTypes.object,
  setLetterSub: PropTypes.func,
};

export const NewLetter = (props) => {
  const radioOptions = props.radioOptions;
  const index = props.index;

  return (
    <div className="gray-border" style={
      { display: 'inline-block', padding: '2rem 2rem', marginLeft: '3rem', marginBottom: '3rem', width: '90%' }
    }>
      <div className="response_letter_date">
        <DateSelector
          name="date-set"
          label="Date sent"
          // value={VADORDate}
          // errorMessage={this.state.dateError}
          // onChange={ }
          type="date"
        />
      </div>
      <br />
      <SearchableDropdown
        name="response-letter-type"
        label="Letter type"
        placeholder="Select..."
        styling={{ maxWidth: '100%' }}
        options={props.letterTypesData}
        value={props.letterType}
        onChange={(val) => props.changeLetterTitle(val)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-title"
        label="Letter title"
        placeholder="Select..."
        readOnly = {props.letterType.length === 0}
        options={props.letterTitleSelector}
        value={props.letterTitle}
        onChange={(val) => props.setLetterTitle(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory"
        label="Letter subcategory"
        placeholder="Select..."
        readOnly = {props.letterTitle.length === 0}
        // options={this.state.packageOptions}
        // value={props.setLetterSubSelector}
        // onChange={this.packageDocumentOnChange}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory-reason"
        label="Letter subcategory reason"
        placeholder="Select..."
        readOnly
        // options={this.state.packageOptions}
        // value={}
        // onChange={this.packageDocumentOnChange}
      />
      <br />
      <RadioField
        name="How long should the response window be for this response letter?"
        options={radioOptions}
        onChange={(val) => props.handleCustomWindowState(val)}
      />
      {props.customWindows &&
        <TextareaField
          name="content"
          label="Provide context and instruction on this task"
          // value={task.content}
          // onChange={updateTaskContent}
        />
      }
      <br />
      <Button
        name="Remove"
        styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
        onClick={() => props.removeLetter(index)}
        classNames={['cf-btn-link', 'cf-right-side']}
      >
        <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
      </Button>
    </div>
  );
};

NewLetter.propTypes = {
  radioOptions: PropTypes.array.isRequired,
  removeLetter: PropTypes.func.isRequired,
  index: PropTypes.number.isRequired,
  handleCustomWindowState: PropTypes.func,
  customWindows: PropTypes.bool,
  setLetterType: PropTypes.func,
  letterType: PropTypes.string,
  letterTitle: PropTypes.string,
  setLetterTitle: PropTypes.func,
  letterTypesData: PropTypes.func,
  letterTitlesData: PropTypes.func,
  changeLetterTitle: PropTypes.func,
  letterTitleSelector: PropTypes.object,


};

export default AddLetter;
