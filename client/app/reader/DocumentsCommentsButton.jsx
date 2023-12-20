import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import ToggleButton from '../components/ToggleButton';
import Button from '../components/Button';
import { connect } from 'react-redux';
import { setViewingDocumentsOrComments } from '../reader/DocumentList/DocumentListActions';
import { DOCUMENTS_OR_COMMENTS_ENUM } from './DocumentList/actionTypes';

class DocumentsCommentsButton extends PureComponent {
  render = () => (
    <div className="cf-documents-comments-control">
      <span id="toggle-label" className="cf-show-all-label" aria-label="Show all">Show all:</span>
      <ToggleButton
        active={this.props.viewingDocumentsOrComments}
        onClick={this.props.setViewingDocumentsOrComments}
      >
        <Button
          id="button-documents"
          ariaLabel={DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS}
          name={DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS}
          styling={{
            'aria-labelledby': 'toggle-label button-documents',
            'aria-selected':
              this.props.viewingDocumentsOrComments ===
              DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
          }}
        >
          Documents
        </Button>
        <Button
          id="button-comments"
          ariaLabel={DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS}
          name={DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS}
          styling={{
            'aria-labelledby': 'toggle-label button-comments',
            'aria-selected':
              this.props.viewingDocumentsOrComments ===
              DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS,
          }}
        >
          Comments
        </Button>
      </ToggleButton>
    </div>
  );
}

export default connect(
  (state) => ({
    viewingDocumentsOrComments: state.documentList.viewingDocumentsOrComments,
  }),
  (dispatch) =>
    bindActionCreators(
      {
        setViewingDocumentsOrComments,
      },
      dispatch
    )
)(DocumentsCommentsButton);

DocumentsCommentsButton.propTypes = {
  setViewingDocumentsOrComments: PropTypes.func.isRequired,
  viewingDocumentsOrComments: PropTypes.string
};
