// client/app/admin/components/CaseflowDistribution/InteractableLever.js

import React from 'react';
import PropTypes, { number } from 'prop-types';
import { css } from 'glamor';
import TextField from 'app/components/TextField';
import RadioField from 'app/components/RadioField';

const activeLever = css({
  width: '100%',
  marginTop: '30px'
});

const leverLeft = css({
  width: '70%',
  display: 'inline-block',
  verticalAlign: 'top',
  marginRight: '30px',
  '& p' : {fontSize: '12px'}
});

const leaverRight = css({
  width: '25%',
  display: 'inline-block',
  '& input' : {width: '60px', height:'20px', marginRight: '10px', fontSize: '12px', display: 'inline-block'},
  '& .cf-form-radio span' : {display: 'none'}
});

const radioOptions = [{
  displayText: 'True',
  value: 0
}, {
  displayText: 'False',
  value: 1
}];

const radioOptions2 = [{
  displayText: 'Option 1',
  value: 0
}];

const radioOptions3 = [{
  displayText: 'Option 2',
  value: 0
}, {
  displayText: 'Option 3',
  value: 1
}];

const radioOnChange =() => {
  console.log("I am changed :" +this.options)
}

const InteractableLever = ({ lever }) => {
  if(lever.data_type=='boolean'){
    return (
      <div className={activeLever}>
        <div className={leverLeft}>
          <strong>{lever.title}</strong>
          <p>{lever.description}</p>
        </div>
        <div className={leaverRight}>
          <RadioField
              vertical
              label={false}
              name={lever.item}
              options={radioOptions}
              // key={approxDecisionDate}
              // value={this.state.selectedContestableIssueIndex}
              // onChange={this.radioOnChange}
            />
          <span>{lever.unit}</span>
        </div>
      </div>
    );
  }
  else if(lever.data_type=='number'){
    return (
      <div className={activeLever}>
        <div className={leverLeft}>
          <strong>{lever.title}</strong>
          <p>{lever.description}</p>
        </div>
        <div className={leaverRight}>
          <input type="number" value={lever.value} />
          {/* <TextField
              maxLength={4}
              name="page"
              // label="Page"
              // onChange={setPageNumber}
              // onKeyPress={handleKeyPress}
              value={lever.value}
              // required={true}
              type={number}
          /> */}
          <span>{lever.unit}</span>
        </div>
      </div>
    );
  }
  else if(lever.data_type=='radio'){
    return (
      <div className={activeLever}>
        <div className={leverLeft}>
          <strong>{lever.title}</strong>
          <p>{lever.description}</p>
        </div>
        <div className={leaverRight}>
            <RadioField
              vertical
              label={false}
              name={lever.item}
              options={radioOptions2}
              // key={approxDecisionDate}
              // value={this.state.selectedContestableIssueIndex}
              onChange={radioOnChange}
            />
          <input type="text" value={lever.value} />
          <RadioField
              vertical
              label={false}
              name={lever.item}
              options={radioOptions3}
              // key={approxDecisionDate}
              // value={this.state.selectedContestableIssueIndex}
              onChange={radioOnChange}
            />
          {/* <input type="text" value={lever.value} /> */}
          {/* <TextField
              maxLength={4}
              name="page"
              // label="Page"
              // onChange={setPageNumber}
              // onKeyPress={handleKeyPress}
              value={lever.value}
              // required={true}
              type={number}
          /> */}
          <span>{lever.unit}</span>
        </div>
      </div>
    );
  }
  else if(lever.data_type=='combination'){
    return (
      <div className={activeLever}>
        <div className={leverLeft}>
          <strong>{lever.title}</strong>
          <p>{lever.description}</p>
        </div>
        <div className={leaverRight}>
          <input type="text" value='Toggle' />
          {/* <TextField
              maxLength={4}
              name="page"
              // label="Page"
              // onChange={setPageNumber}
              // onKeyPress={handleKeyPress}
              value={lever.value}
              // required={true}
              type={number}
          /> */}
          <span>{lever.unit}</span>
        </div>
      </div>
    );
  }
  else {
    return null;
  }
};

InteractableLever.propTypes = {
  lever: PropTypes.shape({
    title: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    data_type: PropTypes.string.isRequired,
    value: PropTypes.number.isRequired,
    unit: PropTypes.string.isRequired,
    is_active: PropTypes.bool.isRequired,
    options: PropTypes.array
  })
};

export default InteractableLever;
