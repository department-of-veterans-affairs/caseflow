import React from 'react';
import PropTypes from 'prop-types';
import DropdownButton from 'app/components/DropdownButton';
import { LIST_SCHEDULE_VIEWS } from 'app/hearings/constants';

export const SwitchViewDropdown = ({ onSwitchView }) => {
  return (
    <DropdownButton
      lists={[
        {
          title: 'Your Hearing Schedule',
          value: LIST_SCHEDULE_VIEWS.DEFAULT_VIEW },
        {
          title: 'Complete Hearing Schedule',
          value: LIST_SCHEDULE_VIEWS.SHOW_ALL }
      ]}
      onClick={onSwitchView}
      label="Switch View" />
  );
};

SwitchViewDropdown.propTypes = {
  onSwitchView: PropTypes.func
};
