// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import { ArrowDownIcon } from 'app/components/icons/ArrowDownIcon';
import { ArrowUpIcon } from 'app/components/icons/ArrowUpIcon';
import { ArrowLeftIcon } from 'app/components/icons/ArrowLeftIcon';
import { ArrowRightIcon } from 'app/components/icons/ArrowRightIcon';
import Modal from 'app/components/Modal';
import Table from 'app/components/Table';

/**
 * Scroll Keyboard Shortcuts Columns
 */
export const scrollColumns = [{
  header: 'Scroll',
  valueName: 'scrollInstruction',
  align: 'left'
},
{
  header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left'
}];

/**
 * Comment Keyboard Shortcut Instructions
 */
export const commentInstructions = [
  {
    commentInstruction: 'Add comment mode',
    shortcut: <span><code>alt</code> + <code>c</code></span>
  },
  {
    commentInstruction: 'Move comment up',
    shortcut: <span><ArrowUpIcon /></span>
  },
  {
    commentInstruction: 'Move comment down',
    shortcut: <span><ArrowDownIcon /></span>
  },
  {
    commentInstruction: 'Move comment left',
    shortcut: <span><ArrowLeftIcon /></span>
  },
  {
    commentInstruction: 'Move comment right',
    shortcut: <span><ArrowRightIcon /></span>
  },
  {
    commentInstruction: 'Place a comment',
    shortcut: <span><code>alt</code> + <code>enter</code></span>
  },
  {
    commentInstruction: 'Save a comment',
    shortcut: <span><code>alt</code> + <code>enter</code></span>
  }
];

/**
 * Comment Keyboard Shortcuts Columns
 */
export const commentColumns = [{
  header: 'Add/ edit comment',
  valueName: 'commentInstruction',
  align: 'left'
},
{
  header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left'
}];

/**
 * Search Keyboard Shortcut Columns
 */
export const searchColumns = [{
  header: 'Search within document',
  valueName: 'searchInstruction',
  align: 'left'
}, {
  header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left'
}];

/**
 * Search Keyboard Shortcut Instructions
 */
export const searchInstructions = () => {
  // Set the Meta Key based on the users OS
  const metaKey = navigator.appVersion && navigator.appVersion.includes('Mac') ? 'ctrl' : 'cmd';

  // Return the Instructions
  return [
    {
      searchInstruction: 'Open search box',
      shortcut: <span><code>{metaKey}</code> + <code>f</code></span>
    },
    {
      searchInstruction: 'Navigate search results',
      shortcut: <span><code>{metaKey}</code> + <code>g</code></span>
    }
  ];
};

/**
 * Document Keyboard Shortcut Instructions
 */
export const docInstructions = [
  {
    documentsInstruction: 'Scroll page up',
    shortcut: <span><code>shift</code> + <code>space</code></span>
  },
  {
    documentsInstruction: 'Scroll page down',
    shortcut: <span><code>space</code></span>
  },
  {
    documentsInstruction: 'View next document',
    shortcut: <span><ArrowRightIcon /></span>
  },
  {
    documentsInstruction: 'View previous document',
    shortcut: <span><ArrowLeftIcon /></span>
  },
  {
    documentsInstruction: 'Open/ Hide menu',
    shortcut: <span><code>alt</code> + <code>m</code></span>
  },
  {
    documentsInstruction: 'Back to document list',
    shortcut: <span><code>alt</code> + <code>backspace</code></span>
  }
];

/**
 * Document Keyboard Shortcut Instructions
 */
export const documentsColumns = [{
  header: 'Navigate reader',
  valueName: 'documentsInstruction',
  align: 'left'
},
{
  header: 'Shortcut',
  valueName: 'shortcut',
  align: 'left'
}];

/**
 * Keyboard Info Component
 * @param {Object} props -- Contains functions for toggling the keyboard info
 */
export const KeyboardInfo = ({ toggleKeyboardInfo, show, ...props }) => show && (
  <div className="cf-modal-scroll">
    <Modal
      id="cf-keyboard-modal"
      title="Keyboard shortcuts"
      buttons={[{
        classNames: ['usa-button', 'usa-button-secondary'],
        name: 'Thanks, got it!',
        onClick: () => toggleKeyboardInfo(false)
      }]}
      closeHandler={() => toggleKeyboardInfo(false)}
      noDivider
    >
      <div className="cf-keyboard-modal-scroll">
        <Table columns={documentsColumns} rowObjects={docInstructions} getKeyForRow={(index) => index} {...props} />
        <Table columns={searchColumns} rowObjects={searchInstructions()} getKeyForRow={(index) => index} {...props} />
        <Table columns={commentColumns} rowObjects={commentInstructions} getKeyForRow={(index) => index} {...props} />
      </div>
    </Modal>
  </div>
);

KeyboardInfo.defaultProps = {
  props: {
    slowReRendersAreOk: true,
    className: 'cf-keyboard-modal-table'
  }
};

KeyboardInfo.propTypes = {
  props: PropTypes.object,
  toggleKeyboardInfo: PropTypes.func,
  show: PropTypes.bool,
};
