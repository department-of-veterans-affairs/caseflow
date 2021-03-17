// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import {
  startEditAnnotation,
  openAnnotationDeleteModal,
  openAnnotationShareModal
} from 'app/reader/AnnotationLayer/AnnotationActions';
import { INTERACTION_TYPES } from 'app/reader/analytics';
import Button from 'app/components/Button';

/**
 * Control Buttons Component for the Comment Component
 * @param {Object} props -- Props containing the Unique ID of the Comment
 */
export const ControlButtons = ({ uuid }) => {
  // Create the Dispatcher
  const dispatch = useDispatch();

  return (
    <div>
      <Button
        name={`delete-comment-${uuid}`}
        classNames={['cf-btn-link comment-control-button']}
        onClick={() => dispatch(openAnnotationDeleteModal(uuid, INTERACTION_TYPES.VISIBLE_UI))}>
          Delete
      </Button>
      <span className="comment-control-button-divider">
          |
      </span>
      <Button
        name={`edit-comment-${uuid}`}
        classNames={['cf-btn-link comment-control-button']}
        onClick={() => dispatch(startEditAnnotation(uuid))}>
          Edit
      </Button>
      <span className="comment-control-button-divider">
          |
      </span>
      <Button
        name={`share-comment-${uuid}`}
        classNames={['cf-btn-link comment-control-button']}
        onClick={() => dispatch(openAnnotationShareModal(uuid, INTERACTION_TYPES.VISIBLE_UI))}>
          Share
      </Button>
    </div>
  );
};

ControlButtons.propTypes = {
  uuid: PropTypes.string
};
