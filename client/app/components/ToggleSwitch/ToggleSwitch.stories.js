import React, {useState} from 'react';
import ToggleSwitch from './ToggleSwitch';

export default {
  title: 'Commons/Components/ToggleSwitch',
  component: ToggleSwitch
};

export const toggleSwitchOn = (args) => {
    const [selected, setSelected] = useState(true);
    return <ToggleSwitch
        id="toogle-switch-on"
        selected={selected}
        toggleSelected={() => {
            setSelected(!selected);
        }} />
};

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
