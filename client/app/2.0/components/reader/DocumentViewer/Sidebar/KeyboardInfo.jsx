// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import { Keyboard } from 'app/components/RenderFunctions';
import Button from 'app/components/Button';

/**
 * Keyboard Info Component
 * @param {Object} props -- Contains functions for toggling the keyboard info
 */
export const KeyboardInfo = ({ toggleKeyboardInfo }) => (
  <div className="cf-keyboard-shortcuts">
    <Button
      id="cf-open-keyboard-modal"
      name={<span><Keyboard />&nbsp; View keyboard shortcuts</span>}
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
