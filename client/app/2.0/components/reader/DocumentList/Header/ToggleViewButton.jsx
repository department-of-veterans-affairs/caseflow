// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { useDispatch } from 'react-redux';

// Local Dependencies
import ToggleButton from 'app/components/ToggleButton';
import Button from 'app/components/Button';
import { setViewingDocumentsOrComments } from 'app/reader/DocumentList/DocumentListActions';
import { DOCUMENTS_OR_COMMENTS_ENUM } from 'app/reader/DocumentList/actionTypes';

/**
 * Toggle View Button Component
 * @param {Object} props -- Props containing the current document list view (Comments|Documents)
 */
export const ToggleViewButton = ({ viewingDocumentsOrComments }) => {
  // Create the dispatcher
  const dispatch = useDispatch();

  return (
    <div className="cf-documents-comments-control">
      <span className="cf-show-all-label">Show all:</span>
      <ToggleButton
        active={viewingDocumentsOrComments}
        onClick={() => dispatch(setViewingDocumentsOrComments)}>

        <Button name={DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS}>
         Documents
        </Button>
        <Button name={DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS}>
         Comments
        </Button>
      </ToggleButton>
    </div>
  );
};

ToggleViewButton.propTypes = {
  viewingDocumentsOrComments: PropTypes.string,
};
