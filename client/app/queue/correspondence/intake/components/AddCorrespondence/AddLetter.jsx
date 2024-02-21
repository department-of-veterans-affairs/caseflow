import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import TextField from '../../../../../components/TextField';
import Button from '../../../../../components/Button';
import { css } from 'glamor';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import RadioField from '../../../../../components/RadioField';
import { ADD_CORRESPONDENCE_LETTER_SELECTIONS } from '../../../../constants';
import moment from 'moment';
import { connect, useDispatch } from 'react-redux';
import { bindActionCreators } from 'redux';
import {
  setResponseLetters
} from '../../../correspondenceReducer/correspondenceActions';

export const AddLetter = (props) => {
  const onContinueStatusChange = props.onContinueStatusChange;

  const [letters, setLetters] = useState([]);
  const [dataLetter, setDataLetter] = useState([]);

  const addLetter = (index) => {
    setLetters([...letters, index]);
  };

  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);

  const canContinue = (currentLetters) => {
    const output = [];
    const opts = ['65 days', 'No response window'];

    for (const [, value] of Object.entries(currentLetters)) {
      if ((value !== null) && (value !== '')) {
        output.push(value);
      }
    }

    if ((output.length === 7) && (opts.includes(output[6]))) {
      return true;
    } else if (output.length === 8) {
      return true;
    }

    return false;
  };

  const taskUpdatedCallback = (updatedTask) => {
    const filtered = dataLetter.filter((cdl) => cdl.id !== updatedTask.id);

    setDataLetter([...filtered, updatedTask]);
  };

  const removeLetter = (index) => {
    const restLetters = letters.filter((letter) => letter !== index);
    const dls = dataLetter.filter((dl) => dl.id !== index);

    setLetters(restLetters);
    setDataLetter(dls);
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

  useEffect(() => {
    if ((dataLetter.length > 0) && letters.length === dataLetter.length) {
      for (let i = 0; i < dataLetter.length; i++) {
        if (canContinue(dataLetter[i])) {
          setUnrelatedTasksCanContinue(true);
        } else {
          setUnrelatedTasksCanContinue(false);
        }
      }
    } else if (letters.length === 0) {
      setUnrelatedTasksCanContinue(true);
    } else {
      setUnrelatedTasksCanContinue(false);
    }

  }, [dataLetter]);

  return (
    <>
      <div className="myletters" style={{width: '100%', display: 'inline-block' }}>
        { letters.map((letter) => (
          <div id={letter} style={{ width: '50%', float: 'left', height: '840px' }} key={letter}>
            <NewLetter
              index={letter}
              removeLetter={removeLetter}
              taskUpdatedCallback={taskUpdatedCallback}
              setUnrelatedTasksCanContinue= {setUnrelatedTasksCanContinue}
            />
          </div>
        )) }
      </div>
      <div style={{ width: '80%', marginBottom: '30px' }}>
        <Button
          type="button"
          name="addLetter"
          className={['cf-left-side']}
          disabled= {!(letters.length < 3)}
          onClick={() => {
            if (letters.length > 0) {
              addLetter(letters[letters.length - 1] + 1);
            } else {
              addLetter(letters.length + 1);
            }
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
  setUnrelatedTasksCanContinue: PropTypes.func,
  onContinueStatusChange: PropTypes.func,
};

const currentDate = moment(new Date()).format('YYYY-MM-DD');
const NewLetter = (props) => {
  const index = props.index;
  const letterHash = {};
  const setUnrelatedTasksCanContinue = props.setUnrelatedTasksCanContinue;
  const [letterCard, setLetterCard] = useState({
    id: index,
    date: currentDate,
    type: '',
    title: '',
    subType: '',
    reason: '',
    responseWindows: '',
    customValue: null
  });

  const [letterTitleSelector, setLetterTitleSelector] = useState('');
  const [letterSubSelector, setLetterSubSelector] = useState('');
  const [letterSubReason, setLetterSubReason] = useState('');
  const [customResponseWindowState, setCustomResponseWindowState] = useState(false);

  const [stateOptions, setStateOptions] = useState(true);

  const [responseWindows, setResponseWindows] = useState('');
  const naValue = 'N/A';
  const dispatch = useDispatch();

  const radioOptions = [
    { displayText: '65 days',
      value: '65 days',
      disabled: stateOptions },
    { displayText: 'No response window',
      value: 'No response window',
      disabled: stateOptions },
    { displayText: 'Custom',
      value: 'Custom',
      disabled: stateOptions }
  ];

  const [valueOptions, setValueOptions] = useState(radioOptions);

  const handleDays = (value) => {
    const currentNumber = parseInt(value.trim(), 10);

    if ((currentNumber >= 1) && (currentNumber <= 64)) {
      setLetterCard({ ...letterCard,
        customValue: currentNumber });
    } else {
      setLetterCard({ ...letterCard,
        customValue: null });
    }
  };

  const handleCustomWindowState = (currentOpt) => {
    if (currentOpt === radioOptions[2].value) {
      setResponseWindows(radioOptions[2].value);
      setCustomResponseWindowState(true);
    } else {
      setResponseWindows(currentOpt);
      setCustomResponseWindowState(false);
      setLetterCard({ ...letterCard,
        customValue: null });
    }
  };

  const letterTypesData = ADD_CORRESPONDENCE_LETTER_SELECTIONS.map((option) => ({ label: (option.letter_type),
    value: option.letter_type }));

  const selectResponseWindows = (option, aux) => {
    if (option.response_window_option_default) {
      setLetterCard({ ...letterCard,
        responseWindows: option.response_window_option_default });
      setResponseWindows(option.response_window_option_default);
    } else if (option.letter_titles[aux].letter_title === letterCard.title) {
      setLetterCard({ ...letterCard,
        responseWindows: option.letter_titles[aux].response_window_option_default });
      setResponseWindows(option.letter_titles[aux].response_window_option_default);
    }
  };

  const canContinue = () => {
    const output = [];
    const opts = ['65 days', 'No response window'];

    for (const [, value] of Object.entries(letterCard)) {
      if ((value !== null) && (value !== '')) {
        output.push(value);
      }
    }

    if ((output.length === 7) && (opts.includes(output[6]))) {
      return true;
    } else if (output.length === 8) {
      return true;
    }

    return false;
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
      setLetterSubSelector([{ label: naValue, value: naValue }]);
    } else {
      setLetterSubSelector(subCate);
    }

    for (let aux1 = 0; aux1 < option.letter_titles[aux].letter_subcategories.length; aux1++) {
      if (letterCard.subType === option.letter_titles[aux].letter_subcategories[aux1].subcategory) {
        option.letter_titles[aux].letter_subcategories[aux1].reasons.map((currentReason) =>
          listReason.push({ label: currentReason, value: currentReason }));
      }
    }

    if (listReason.length === 0) {
      setLetterSubReason([{ label: naValue, value: naValue }]);
    } else {
      setLetterSubReason(listReason);
    }
  };

  const findSubCategoryReason = (option) => {
    for (let aux = 0; aux < option.letter_titles.length; aux++) {
      if (option.letter_titles[aux].letter_title === letterCard.title) {
        findSub(option, aux);
      } else {
        selectResponseWindows(option, aux);
      }
    }
  };

  const activateWindowsOption = () => {
    if (responseWindows.trim().length > 0) {
      for (let i = 0; i < valueOptions.length; i++) {
        const option = valueOptions[i];

        setStateOptions(false);
        option.disabled = false;
      }
      setValueOptions(valueOptions);
    } else {
      for (let i = 0; i < valueOptions.length; i++) {
        const option = valueOptions[i];

        setStateOptions(true);
        option.disabled = true;
      }
      setValueOptions(valueOptions);
    }
  };

  const letterTitlesData = () => {
    for (let i = 0; i < ADD_CORRESPONDENCE_LETTER_SELECTIONS.length; i++) {
      const option = ADD_CORRESPONDENCE_LETTER_SELECTIONS[i];

      if (option.letter_type === letterCard.type) {
        setLetterTitleSelector(option.letter_titles.map((current) => ({
          label: current.letter_title, value: current.letter_title
        })));

        if (letterCard.type.length > 0) {
          findSubCategoryReason(option);
        }
      }
    }
  };

  useEffect(() => {
    if (canContinue()) {
      letterHash[index] = letterCard;
      dispatch(setResponseLetters(letterHash));
      setUnrelatedTasksCanContinue(true);
      props.taskUpdatedCallback(letterCard);
    } else {
      setUnrelatedTasksCanContinue(false);
    }
  }, [letterCard]);

  useEffect(() => {
    activateWindowsOption();
    setLetterCard({ ...letterCard,
      responseWindows });
  }, [responseWindows]);

  useEffect(() => {
    if (letterCard.type.length > 0) {
      letterTitlesData();
    }
  }, [letterCard.type]);

  useEffect(() => {
    if (letterCard.subType.length > 0) {
      letterTitlesData();
    }
  }, [letterCard.subType]);

  const changeLetterType = (val) => {
    setLetterCard({ ...letterCard,
      type: val,
      title: '',
      subType: '',
      reason: '',
      responseWindows: ''
    });
    setCustomResponseWindowState(false);
  };

  useEffect(() => {
    if (letterCard.title.length > 0) {
      letterTitlesData();
      if (responseWindows.length > 0) {
        activateWindowsOption();
      }
    }
  }, [letterCard.title]);

  const changeLetterTitle = (val) => {
    setLetterCard({ ...letterCard,
      title: val,
      subType: '',
      reason: '',
      responseWindows: ''
    });
    setCustomResponseWindowState(false);
  };

  const changeLetterSubTitle = (val) => {
    setLetterCard({ ...letterCard,
      subType: val,
      reason: '',
      customValue: null
    });
    setCustomResponseWindowState(false);
  };

  const changeSubReason = (val) => {
    setLetterCard({ ...letterCard,
      reason: val,
      customValue: null
    });
  };

  const changeDate = (val) => {
    setLetterCard({ ...letterCard,
      date: val
    });
  };

  const removeLetter = () => {
    props.removeLetter(index);
  };

  const letterSelectorStyling = css({
    '& .cf-select__control': {
      maxWidth: '60rem !important',
    },
  });

  const letterDateStyling = css({
    '.cf-form-textinput': {
      maxWidth: '60rem !important',
    },
  });

  return (
    <div className="gray-border" style={
      { display: 'inline-block', padding: '2rem 2rem', marginBottom: '3rem', width: '95%' }
    }>
      <div className="response_letter_date">
        <DateSelector
          name="date-set"
          label="Date sent"
          value= {letterCard.date}
          onChange={(val) => changeDate(val)}
          type="date"
          inputStyling={letterDateStyling}
        />
      </div>
      <br />
      <SearchableDropdown
        name="response-letter-type"
        label="Letter type"
        placeholder="Select..."
        styling={letterSelectorStyling}
        options={letterTypesData}
        value={letterCard.type}
        onChange={(val) => changeLetterType(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-title"
        label="Letter title"
        placeholder="Select..."
        styling={letterSelectorStyling}
        readOnly = {letterCard.type.length === 0}
        options={letterTitleSelector}
        value={letterCard.title}
        onChange={(val) => changeLetterTitle(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory"
        label="Letter subcategory"
        placeholder="Select..."
        styling={letterSelectorStyling}
        readOnly = {letterCard.title.length === 0}
        options={letterSubSelector}
        value={letterCard.subType}
        onChange={(val) => changeLetterSubTitle(val.value)}
      />
      <br />
      <SearchableDropdown
        name="response-letter-subcategory-reason"
        label="Letter subcategory reason"
        placeholder="Select..."
        styling={letterSelectorStyling}
        readOnly = {letterCard.subType.length === 0}
        options={letterSubReason}
        value={letterCard.reason}
        onChange={(val) => changeSubReason(val.value)}
      />
      <br />
      <RadioField
        label="How long should the response window be for this response letter?"
        name={`How long should the response window be for this response letter?-${index}`}
        options={valueOptions}
        value = {responseWindows}
        onChange={(val) => handleCustomWindowState(val)}
      />

      { customResponseWindowState &&
        <TextField
          label="Number of days (Value must be between 1 and 64)"
          name="content"
          useAriaLabel
          inputStyling={letterDateStyling}
          onChange={handleDays}
          value={letterCard.customValue}
        />
      }
      <br />
      <Button
        name="Remove"
        styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
        onClick={() => removeLetter()}
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
  setLetterType: PropTypes.func,
  letterType: PropTypes.string,
  letterTitle: PropTypes.string,
  setLetterTitle: PropTypes.func,
  setResponseLetters: PropTypes.func,
  setUnrelatedTasksCanContinue: PropTypes.func,
  taskUpdatedCallback: PropTypes.func,
  onContinueStatusChange: PropTypes.func
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    setResponseLetters
  }, dispatch)
);

export default connect(
  mapDispatchToProps
)(NewLetter);

