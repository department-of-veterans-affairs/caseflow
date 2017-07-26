import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import ToggleButton from '../components/ToggleButton';
import Button from '../components/Button';
import { connect } from 'react-redux';
import { setViewingDocumentsOrComments } from './actions';
import { DOCUMENTS_OR_COMMENTS_ENUM } from './constants';

class DocumentsCommentsButton extends PureComponent {
  render = () => <div className="cf-documents-comments-control">
    <span className="cf-show-all-label">Show all:</span>
    <ToggleButton
      active={this.props.viewingDocumentsOrComments}
      onClick={this.props.setViewingDocumentsOrComments}>

      <Button name={DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS}>
        Documents
      </Button>
      <Button name={DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS}>
        Comments
      </Button>
    </ToggleButton>
  </div>;
}

export default connect(
  (state) => ({
    viewingDocumentsOrComments: state.viewingDocumentsOrComments
  }),
  (dispatch) => bindActionCreators({
    setViewingDocumentsOrComments
  }, dispatch)
)(DocumentsCommentsButton);
