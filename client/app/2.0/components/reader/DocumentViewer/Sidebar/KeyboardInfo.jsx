// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import { KeyboardIcon } from 'app/components/icons/KeyboardIcon';
import Button from 'app/components/Button';

/**
 * KeyboardIcon Info Component
 * @param {Object} props -- Contains functions for toggling the keyboard info
 */
export const KeyboardInfo = ({ toggleKeyboardInfo }) => (
  <div className="cf-keyboard-shortcuts">
    <Button
      id="cf-open-keyboard-modal"
      name={<span><KeyboardIcon />&nbsp; View keyboard shortcuts</span>}
      onClick={() => toggleKeyboardInfo(true)}
      classNames={['cf-btn-link']}
    />
  </div>
);

KeyboardInfo.defaultProps = {
  tableProps: {
    slowReRendersAreOk: true,
    className: 'cf-keyboard-modal-table'
  }
};

KeyboardInfo.propTypes = {
  tableProps: PropTypes.object,
  toggleKeyboardInfo: PropTypes.func,
};
