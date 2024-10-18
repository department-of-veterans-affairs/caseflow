/* eslint-disable max-lines, max-len */

import React, { useState } from 'react';
import PropTypes from 'prop-types';

import Checkbox from '../../components/Checkbox';

export default function FunctionConfiguration(props) {
  const [isChecked, functionIsChecked] = useState(false);
  const [selectedFunctions, setSelectedFunctions] = useState({});

  let functionOption = props.functionOption;
  let currentState = props.currentState;
  let updateState = props.updateState;

  /**
 * This function handles the checking of the box and updates state.
 * @param {selectedFunction} selectedFunction is the selected checkbox value
 * @returns {updatedSelections} a copy of the state object that tracks function selections.
 */
  const handleFunctionSelect = (selectedFunction) => {
    functionIsChecked(!isChecked);
    setSelectedFunctions((prev) => {
      const updatedSelections = { ...prev };

      if (updatedSelections[selectedFunction]) {
        delete updatedSelections[selectedFunction];
      } else {
        updatedSelections[selectedFunction] = true;
      }
      updateState(
        {
          ...currentState,
          user: {
            ...currentState.user,
            user: {
              ...currentState.user.user,
              functions: updatedSelections
            }
          }
        }
      );

      return updatedSelections;
    });
  };

  return (
    <div className="load-test-container-checkbox">
      <Checkbox
        label={functionOption}
        name={functionOption}
        onChange={() => {
          handleFunctionSelect(functionOption);
        }}
        isChecked={Boolean(selectedFunctions[functionOption])}
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
