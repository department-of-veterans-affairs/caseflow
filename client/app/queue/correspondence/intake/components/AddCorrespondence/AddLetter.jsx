import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
// import { connect } from 'react-redux';
// import { bindActionCreators } from 'redux';
import TextField from '../../../../../components/TextField';
import Button from '../../../../../components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import RadioField from '../../../../../components/RadioField';
import { ADD_CORRESPONDENCE_LETTER_SELECTIONS } from '../../../../constants';
import moment from 'moment';

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
  const [subReason, setSubReason] = useState('');

  const currentDate = moment.utc(new Date()).format('YYYY-MM-DD');
  const [date, setDate] = useState(currentDate);
  const [stateOptions, setStateOptions] = useState(true);

  const radioOptions = [
    { displayText: '65 days',
      value: '65 days',
      disabled: stateOptions },
    { displayText: 'No response window',
      value: 'No response window',
      disabled: stateOptions },
    { displayText: 'Custom',
      value: 'Other',
      disabled: stateOptions }
  ];

  const [valueOptions, setValueOptions] = useState(radioOptions);
  const [responseWindows, setResponseWindows] = useState('');

  const letterTypesData = ADD_CORRESPONDENCE_LETTER_SELECTIONS.map((option) => ({ label: (option.letter_type),
    value: option.letter_type }));

  const selectResponseWindows = (option, aux) => {
    if (option.response_window_option_default) {
      setResponseWindows(option.response_window_option_default);
    } else if (option.letter_titles[aux].letter_title === letterTitle) {
      setResponseWindows(option.letter_titles[aux].response_window_option_default);
    }
  };

  const findSub = (option, aux) => {
    const subCate = [];
    const listReason = [];

    selectResponseWindows(option, aux);

    for (let aux1 = 0; aux1 < option.letter_titles[aux].letter_subcategories.length; aux1++) {
      subCate.push({ label: option.letter_titles[aux].letter_subcategories[aux1].subcategory,
        value: option.letter_titles[aux].letter_subcategories[aux1].subcategory });
    }

    if (subCate.length === 0) {
      setLetterSubSelector([{ label: 'N/A', value: 'N/A' }]);
    } else {
      setLetterSubSelector(subCate);
    }

    for (let aux1 = 0; aux1 < option.letter_titles[aux].letter_subcategories.length; aux1++) {
      if (letterSub === option.letter_titles[aux].letter_subcategories[aux1].subcategory) {
        option.letter_titles[aux].letter_subcategories[aux1].reasons.map((currentReason) =>
          listReason.push({ label: currentReason, value: currentReason }));
      }
    }

    if (listReason.length === 0) {
      setLetterSubReason([{ label: 'N/A', value: 'N/A' }]);
    } else {
      setLetterSubReason(listReason);
    }
  };

  const setRadioValue = () => {
    for (let i = 0; i < valueOptions.length; i++) {
      const option = valueOptions[i];

      if (responseWindows === option.displayText) {
        setStateOptions(false);
        option.disabled = false;
        if (responseWindows === '65 days') {
          valueOptions[2].disabled = false;
          break;
        }
      } else {
        setStateOptions(true);
        option.disabled = true;
      }
    }
    setValueOptions(valueOptions);
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
            findSub(option, aux);
          } else {
            selectResponseWindows(option, aux);
          }
        }
      }
    }
  };

  useEffect(() => {
    if (responseWindows.length > 0) {
      letterTitlesData();
      setRadioValue();
    }
  }, [responseWindows]);

  useEffect(() => {
    if (letterType.length > 0) {
      letterTitlesData();
    }
  }, [letterType]);

  const changeLetterType = (val) => {
    setLetterTitle('');
    setLetterType(val);
    setValueOptions(radioOptions);
    // resetResponseWindows();
  };

  useEffect(() => {
    if (letterTitle.length > 0) {
      letterTitlesData();
    }
  }, [letterTitle]);

  const changeLetterTitle = (val) => {
    setLetterTitle(val);
    setRadioValue();

  };

  useEffect(() => {
    if (letterSub.length > 0) {
      letterTitlesData();
    }
  }, [letterSub]);

  const changeLetterSubTitle = (val) => {
    setLetterSub(val);
  };

  return (
    <div className="gray-border" style={
      { display: 'inline-block', padding: '2rem 2rem', marginLeft: '3rem', marginBottom: '3rem', width: '90%' }
    }>
      <div className="response_letter_date">
        <DateSelector
          name="date-set"
          label="Date sent"
          value= {date}
          onChange={(val) => setDate(val)}
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
        value={letterSub.length}
        onChange={(val) => changeLetterSubTitle(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory-reason"
        label="Letter subcategory reason"
        placeholder="Select..."
        readOnly = {letterSub.length === 0}
        options={letterSubReason}
        value={subReason}
        // onChange={this.packageDocumentOnChange}
      />
      <br />
      <RadioField
        name="How long should the response window be for this response letter?"
        options={valueOptions}
        value = {responseWindows}
        onChange={(val) => props.handleCustomWindowState(val)}
        // optionsStyling={{ marginTop: 0 }}
      />

      { props.customWindows &&
        <TextField
          label="Number of days (Value must be between 0 and 65)"
          name="content"
          useAriaLabel
          // readOnly={props.isReadOnly}
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
        <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove letter
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
