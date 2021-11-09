// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import Button from 'app/components/Button';

/**
 * Jump to Section Button
 * @param {Object} -- Props contain the function and comment to jump
 */
export const JumpButton = ({ uuid, jumpToComment }) => (
  <Button
    name="jumpToComment"
    id={`jumpToComment${uuid}`}
    classNames={['cf-btn-link comment-control-button horizontal']}
    onClick={() => jumpToComment(uuid)}>
    Jump to section
  </Button>
);

JumpButton.propTypes = {
  jumpToComment: PropTypes.func,
  uuid: PropTypes.number,
};
