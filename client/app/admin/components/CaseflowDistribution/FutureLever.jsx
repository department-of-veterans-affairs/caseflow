
import React from 'react';
import PropTypes from 'prop-types';
import TextField from 'app/components/TextField';
import RadioField from '../../../components/RadioField';
import Table from '../../../components/Table';
import NumberField from 'app/components/NumberField';

const StaticLever = ({ lever }) => {
  const booleanOptions = [{
    displayText: 'True',
    value: false
  }, {
    displayText: 'False',
    value: true
  }];
  const radioOptions = [{
    displayText: 'Option 1',
    value: 1
  }, { displayText: 'Option 2',
    value: 2
  }, {
    displayText: 'Option 3',
    value: 3
  }];

  return (
    <div>
      <strong>{lever.title}</strong>
      <p>{lever.description}</p>
      {(() => {
        if (lever.data_type === 'boolean') {
          return (
            <div>
              <RadioField
                vertical
                label={false}
                name={lever.item}
                options={booleanOptions}
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

            <div>
              <RadioField
                vertical
                label={false}
                name={lever.item}
                options={radioOptions}
                onChange={this.onChange}
              />
              <input type="text" value={lever.title} />

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
