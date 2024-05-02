import React from 'react';
import { useDispatch } from 'react-redux';
import RadioField from 'app/components/RadioField';
import { updateLeverValue } from '../reducers/levers/leversActions';

const ExcludeDocketLever = (levers) => {
  const dispatch = useDispatch();
  let selectedLever = levers.lever;
  const onChangeSelected = (selected) => (event) => {
    dispatch(updateLeverValue(selected.leverGroup, selected.item, event));
  };

  return (
    <span>
      <RadioField
        name={selectedLever.displayText}
        hideLabel
        value={selectedLever.value}
        options={selectedLever.options}
        onChange={onChangeSelected(selectedLever)}
        vertical
      />
    </span>
  );
};

export default ExcludeDocketLever;
