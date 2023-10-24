// client/app/admin/components/CaseflowDistribution/InteractableLever.js

import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import TextField from 'app/components/TextField';
import RadioField from 'app/components/RadioField';
import NumberField from 'app/components/NumberField';

const activeLever = css({
  width: '100%',
  padding: '15px',
  borderBottom: '1px solid #e4e2e0',
  boxSizing: 'border-box'
});

const leverLeft = css({
  width: '70%',
  display: 'inline-block',
  verticalAlign: 'top',
  marginRight: '30px',
  '& p': { marginBotton: '0 !important' }
});

const leverRight = css({
  width: '25%',
  display: 'inline-block',
  '& input': {
    width: '60px',
    height: '20px',
    marginRight: '10px',
    fontSize: '12px',
    display: 'inline-block' },
  '& .cf-form-radio span': { display: 'none' },
  '& .cf-form-textinput span': { display: 'none' },
  '& div:first-child': { width: 'auto', display: 'inline-block' }

});

const radioOptions = [{
  displayText: 'True',
  value: false
}, {
  displayText: 'False',
  value: true
}];

const radioOptions2 = [{
  displayText: 'Option 1',
  value: 1
}];

const radioOptions3 = [{
  displayText: 'Option 2',
  value: 2
}, {
  displayText: 'Option 3',
  value: 3
}];

const radioOnChange = () => {
  console.log('Clicked');
};

const StaticLever = ({ lever }) => {
  return (
    <div className={activeLever}>
      <strong>{lever.title}</strong>
      <p>{lever.description}</p>

      {(() => {
        if (lever.data_type === 'boolean') {
          return (
            <div className={leverRight}>
              <RadioField
                vertical
                label={false}
                name={lever.item}
                options={radioOptions}
                value={lever.value}
              />
              <span>{lever.unit}</span>
            </div>
          );
        } else if (lever.data_type === 'number') {
          return (
            <div className={leverRight}>
              <NumberField
                name="number"
                value={lever.value}
              />
              <span>{lever.unit}</span>
            </div>
          );
        } else if (lever.data_type === 'radio') {
          return (
            <div className={leverRight}>
              <RadioField
                vertical
                label={false}
                name={lever.item}
                options={radioOptions2}
                onChange={radioOnChange}
              />
              <input type="text" value={lever.title} />
              <RadioField
                vertical
                label={false}
                name={lever.value}
                options={radioOptions3}
                onChange={radioOnChange}
              />
            </div>
          );
        } else if (lever.data_type === 'combination') {
          return (
            <div className={leverRight}>
              <input type="text" value="Toggle" />
              <span>{lever.unit}</span>
            </div>
          );
        }
      })()}
    </div>
  );
};

StaticLever.propTypes = {
  lever: PropTypes.shape({
    title: PropTypes.string.isRequired,
    description: PropTypes.string.isRequired,
    data_type: PropTypes.string.isRequired,
    value: PropTypes.number.isRequired,
  }).isRequired,
};

export default StaticLever;
