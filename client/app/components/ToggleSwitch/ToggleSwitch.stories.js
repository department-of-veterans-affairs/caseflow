import React, {useState} from 'react';
import ToggleSwitch from './ToggleSwitch';
import { useArgs } from '@storybook/client-api';

export default {
  title: 'Commons/Components/ToggleSwitch',
  component: ToggleSwitch,
  parameters: {
    controls: { expanded: true },
  },
  argTypes: {
    toggleSelected: { action: 'clicked' }
 }
};

export const toggleSwitchOn = (args) => {
  // The usage of args and updateArgs here allows storybook to check/uncheck
  // when you click on the toggleSwitch
  // eslint-disable-next-line no-unused-vars
  const [{selected, toggleSelected}, updateArgs] = useArgs();

  const handleChange = (e) => {
    args.toggleSelected(!selected);
    updateArgs({ selected: !selected })
  };

    return <ToggleSwitch
        id="toogle-switch-on"
        selected={selected}
        toggleSelected={handleChange}
        />
};
toggleSwitchOn.args = {
    selected: true
}

export const toggleSwitchOff = (args) => {
    const [selected, setSelected] = useState(false);
    return <ToggleSwitch
        id="toogle-switchoff"
        selected={selected}
        toggleSelected={() => {
            setSelected(!selected);
        }} />
};

export const toggleSwitchDisabled = (args) => {
    const [selected, setSelected] = useState(false);
    return <ToggleSwitch
        id="toogle-switch-disabled"
        selected={selected}
        disabled={true}
        toggleSelected={() => {
            setSelected(!selected);
        }} />
};
