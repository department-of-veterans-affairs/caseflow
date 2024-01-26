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

// import {
//   setResponseLetters
// } from '../../../correspondenceReducer/correspondenceActions';

export const AddLetter = (props) => {
  const onContinueStatusChange = props.onContinueStatusChange;

  const [letters, setLetters] = useState([]);

  const addLetter = (index) => {
    setLetters([...letters, index]);
  };

  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);
  const [customResponseWindowState, setCustomResponseWindowState] = useState(false);

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

  return (
    <>
      { letters.map((letter) => (
        <div id={letter} style={{ width: '50%', display: 'inline-block' }} key={letter}>
          <NewLetter
            index={letter}
            removeLetter={removeLetter}
            customWindows={customResponseWindowState}
            handleCustomWindowState = {handleCustomWindowState}
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
  removeLetter: PropTypes.func,
  index: PropTypes.number,
  onContinueStatusChange: PropTypes.func,
  customResponseWindowState: PropTypes.bool,
  handleCustomWindowState: PropTypes.func,
};

export const NewLetter = (props) => {
  const index = props.index;

  const [letterType, setLetterType] = useState('');
  const [letterTitle, setLetterTitle] = useState('');
  const [letterTitleSelector, setLetterTitleSelector] = useState();
  const [letterSub, setLetterSub] = useState('');
  const [letterSubSelector, setLetterSubSelector] = useState([]);
  const [letterSubReason, setLetterSubReason] = useState('');
  const [date, setDate] = useState();
  const currentDate = new Date();

  const letterTypesData = ADD_CORRESPONDENCE_LETTER_SELECTIONS.map((option) => ({ label: (option.letter_type),
    value: option.letter_type }));

  const radioOptions = [
    { displayText: '65 days',
      value: '65' },
    { displayText: 'No response window',
      value: 'no_response' },
    { displayText: 'Custom',
      value: 'Other' }
  ];

  const repared = (option, aux) => {
    const subCate = [];

    for (let aux1 = 0; aux1 < option.letter_titles[aux].letter_subcategories.length; aux1++) {
      subCate.push({ label: option.letter_titles[aux].letter_subcategories[aux1].subcategory,
        value: option.letter_titles[aux].letter_subcategories[aux1].subcategory });
    }
    setLetterSubSelector(subCate);
  };

  const selectReason = (option, aux) => {
    const reason = [];

    for (let aux1 = 0; aux1 < option.letter_titles[aux].letter_subcategories.length; aux1++) {
      reason.push({ label: option.letter_titles[aux].letter_subcategories[aux1].subcategory,
        value: option.letter_titles[aux].letter_subcategories[aux1].subcategory });
    }
    setLetterSubReason(reason);
  };

  const repared2 = (option, aux) => {
    const subCate = [];

    for (let aux1 = 0; aux1 < option.letter_titles[aux].letter_subcategories.length; aux1++) {
      if (option.letter_titles[aux].letter_subcategories === letterSub) {
        selectReason(option, aux, aux1);
      }
    }
    setLetterSubSelector(subCate);
  };

  const letterTitlesData = () => {
    for (let i = 0; i < ADD_CORRESPONDENCE_LETTER_SELECTIONS.length; i++) {
      const option = ADD_CORRESPONDENCE_LETTER_SELECTIONS[i];

      if (option.letter_type === letterType) {
        setLetterTitleSelector(option.letter_titles.map((current) => ({
          label: current.letter_title, value: current.letter_title
        })));

        for (let aux = 0; aux < option.letter_titles.length; aux++) {
          if (option.letter_titles[aux].letter_title === letterTitle) {
            repared(option, aux);
          }
        }

        // setLetterSubSelector(option.letter_titles.map((current) => (
        //   (current.letter_title === letterTitle) &&
        //     current.letter_subcategories.map((sub) => (
        //       { label: sub.subcategory, value: sub.subcategory })
        //     )
        // )));

        // setLetterSubReason(option.letter_titles.map((current) => (
        //   current.letter_subcategories.map((reasons) => (
        //     reasons.reasons.map((currentReason) => (
        //       { label: currentReason, value: currentReason })
        //     )
        //   )
        //   )
        // )));

        for (let aux = 0; aux < option.letter_titles.length; aux++) {
          if (option.letter_titles[aux].letter_title === letterTitle) {
            repared2(option, aux);
          }
        }
      }
    }
  };

  useEffect(() => {
    if (letterType.length > 0) {
      letterTitlesData();
    }
  }, [letterType]);

  const changeLetterType = (val) => {
    setLetterType(val);
    // letterTitlesData();
  };

  useEffect(() => {
    if (letterTitle.length > 0) {
      letterTitlesData();
    }
  }, [letterTitle]);

  const changeLetterTitle = (val) => {
    setLetterTitle(val);
    // letterTitlesData();
  };

  useEffect(() => {
    if (letterSub.length > 0) {
      letterTitlesData();
    }
  }, [letterSub]);

  const changeLetterSubTitle = (val) => {
    setLetterSub(val);
    // letterTitlesData();
  };

  return (
    <div className="gray-border" style={
      { display: 'inline-block', padding: '2rem 2rem', marginLeft: '3rem', marginBottom: '3rem', width: '90%' }
    }>
      <div className="response_letter_date">
        <DateSelector
          name="date-set"
          label="Date sent"
          // value=
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
        options={letterTypesData}
        value={letterType}
        onChange={(val) => changeLetterType(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-title"
        label="Letter title"
        placeholder="Select..."
        readOnly = {letterType.length === 0}
        options={letterTitleSelector}
        value={letterTitle}
        onChange={(val) => changeLetterTitle(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory"
        label="Letter subcategory"
        placeholder="Select..."
        readOnly = {letterTitle.length === 0}
        options={letterTitle.length && letterSubSelector}
        value={letterSub}
        onChange={(val) => changeLetterSubTitle(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory-reason"
        label="Letter subcategory reason"
        placeholder="Select..."
        readOnly = {letterSub.length === 0}
        options={letterSubReason}
        value={letterSubReason}
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
  removeLetter: PropTypes.func.isRequired,
  index: PropTypes.number.isRequired,
  handleCustomWindowState: PropTypes.func,
  customWindows: PropTypes.bool,
  setLetterType: PropTypes.func,
  letterType: PropTypes.string,
  letterTitle: PropTypes.string,
  setLetterTitle: PropTypes.func,
};

export default AddLetter;
