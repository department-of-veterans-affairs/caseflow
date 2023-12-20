// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import ToggleButton from 'app/components/ToggleButton';
import Button from 'app/components/Button';
import { DOCUMENTS_OR_COMMENTS_ENUM } from 'app/reader/DocumentList/actionTypes';

/**
 * Toggle View Button Component
 * @param {Object} props -- Props containing the current document list view (Comments|Documents)
 */
export const ToggleViewButton = ({ documentsView, changeView }) => (
  <div className="cf-documents-comments-control">
    <span className="cf-show-all-label">Show all:</span>
    <ToggleButton
      active={documentsView}
      onClick={changeView}>

      <Button name={DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS}
        role="button">
         Documents
      </Button>
      <Button name={DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS}
        role="button">
         Comments
      </Button>
    </ToggleButton>
  </div>
);

ToggleViewButton.propTypes = {
  documentsView: PropTypes.string,
  changeView: PropTypes.func,
};
