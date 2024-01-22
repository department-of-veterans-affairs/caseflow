import React, { useState } from 'react';
import PropTypes from 'prop-types';
// import { connect } from 'react-redux';
// import { bindActionCreators } from 'redux';
// import Checkbox from '../../../../../components/Checkbox';
import Button from '../../../../../components/Button';
import SearchableDropdown from 'app/components/SearchableDropdown';
import DateSelector from 'app/components/DateSelector';
import RadioField from '../../../../../components/RadioField';
// import ApiUtil from '../../../../../util/ApiUtil';

// import {
//   setResponseLetters
// } from '../../../correspondenceReducer/correspondenceActions';

export const AddLetter = () => {

  const [letters, setLetters] = useState([]);
  const [AddLetterButtonState, setAddLetterButtonState] = useState(true);

  const addLetter = (index) => {
    setLetters([...letters, index]);
  };

  const enableAddLeter = () => {
    setAddLetterButtonState(true);
  };

  const disabledAddLetter = () => {
    setAddLetterButtonState(false);
  };

  const radioOptions = [
    { displayText: '65 days',
      value: 65 },
    { displayText: 'No response window',
      value: 'no_response' },
    { displayText: 'Custom',
      value: 'Other' }
  ];

  return (
    <>
      { letters.map((letter) => (
        <div style={{ width: '50%', display: 'inline-block' }}>
          <NewLetter radioOptions={radioOptions} />
        </div>
      )) }

      {AddLetterButtonState &&
        <div style={{ width: '80%', marginBottom: '30px' }}>

          <Button
            type="button"
            name="addLetter"
            className={['cf-left-side']}
            disabled="false"
            onClick={() => {
              addLetter(letters.length + 1);
            }}>
          + Add letter
          </Button>
        </div>
      }
    </>

  );
};

AddLetter.propTypes = {
  radioOptions: PropTypes.object,
};

export const NewLetter = ({
  radioOptions
}) => (

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
      // readOnly
      // options={this.state.packageOptions}
      // value={packageDocument}
      // onChange={this.packageDocumentOnChange}
    />
    <br />
    <SearchableDropdown
      name="response-letter-title"
      label="Letter title"
      placeholder="Select..."
      readOnly
      // options={this.state.packageOptions}
      // value={packageDocument}
      // onChange={this.packageDocumentOnChange}
    />
    <br />
    <SearchableDropdown
      name="response-letter-subcategory"
      label="Letter subcategory"
      placeholder="Select..."
      readOnly
      // options={this.state.packageOptions}
      // value={packageDocument}
      // onChange={this.packageDocumentOnChange}
    />
    <br />
    <SearchableDropdown
      name="response-letter-subcategory-reason"
      label="Letter subcategory reason"
      placeholder="Select..."
      readOnly
      // options={this.state.packageOptions}
      // value={packageDocument}
      // onChange={this.packageDocumentOnChange}
    />
    <br />
    <RadioField
      name="How long should the response window be for this response letter?"
      options={radioOptions}
      // onChange={onChange}
    />
    <br />
    <Button
      name="Remove"
      styling={{ style: { paddingLeft: '0rem', paddingRight: '0rem' } }}
      // onClick={() => () }
      classNames={['cf-btn-link', 'cf-right-side']}
    >
      <i className="fa fa-trash-o" aria-hidden="true"></i>&nbsp;Remove task
    </Button>
  </div>
);

NewLetter.propTypes = {
  radioOptions: PropTypes.object,
};

export default AddLetter;
