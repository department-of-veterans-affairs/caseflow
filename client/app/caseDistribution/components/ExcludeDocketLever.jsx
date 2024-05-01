import React from 'react';
import { useDispatch } from 'react-redux';
import RadioField from 'app/components/RadioField';
import { updateLeverValue } from '../reducers/levers/leversActions';
import ACD_LEVERS from '../../../constants/ACD_LEVERS';

const ExcludeDocketLever = (levers) => {
  const dispatch = useDispatch();
  const LEVER_GROUP = ACD_LEVERS.lever_groups.docket_levers;
  let docketLever = levers.lever;
  let leverName = docketLever?.item ? docketLever.item : '';
  let leverValue = docketLever?.value ? docketLever.value : ''

  const onChangeSelected = (lever) => (event) => {
    const { item } = lever;

    dispatch(updateLeverValue(LEVER_GROUP, item, event));
  };

  const options = [
    { displayText: 'On',
      value: 'true',
      disabled: false
    },
    { displayText: 'Off',
      value: 'false',
      disabled: false
    }
  ];

  return (
    <span>
      <RadioField
        name={leverName}
        hideLabel
        value={leverValue}
        options={options}
        onChange={onChangeSelected(docketLever)}
        vertical
      />
    </span>
  );
};

export default ExcludeDocketLever;
