/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';
import { functions } from 'lodash';

export default function FunctionConfiguration(props) {
  const [isChecked, functionIsChecked] = useState(false);

  let functionOption = props.functionOption;

  const onChangeHandle = (value) => {
    functionIsChecked(!isChecked);
    props.updateState(
      {
        ...props.currentState,
        user: {
          ...props.currentState.user,
          user: {
            ...props.currentState.user.user,
            functions: {
              ...functions,
              [functionOption]: value
            }
          }
        }
      }
    );
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={functionOption}
        name={functionOption}
        onChange={(newVal) => {
          onChangeHandle(newVal);
        }}
        value={isChecked}
      />
    </div>
  );
}

FunctionConfiguration.propTypes = {
  functionOption: PropTypes.string,
  currentState: PropTypes.object,
  updateState: PropTypes.func
};
