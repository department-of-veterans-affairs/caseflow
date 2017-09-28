import React, { PureComponent } from 'react';
import { connect } from 'react-redux';
import EditComment from './EditComment';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { plusIcon } from '../components/RenderFunctions';
import Button from '../components/Button';
import _ from 'lodash';

class SideBarComments extends PureComponent {
  render() {
    let {
      comments,
      handleAddClick,
      placedButUnsavedAnnotation,
      onChange,
      onCancelCommentEdit,
      onSaveCommentEdit,
      showErrorMessage
    } = this.props;

    return <div>
      <span className="cf-right-side cf-add-comment-button">
        <Button
          name="AddComment"
          onClick={handleAddClick}>
          <span>{ plusIcon() } &nbsp; Add a comment</span>
        </Button>
      </span>
    <div id="cf-comment-wrapper" className="cf-comment-wrapper">
      {showErrorMessage.annotation && <CannotSaveAlert />}
      <div className="cf-pdf-comment-list">
        {placedButUnsavedAnnotation &&
          <EditComment
            comment={placedButUnsavedAnnotation}
            id="addComment"
            disableOnEmpty={true}
            onChange={onChange}
            onCancelCommentEdit={onCancelCommentEdit}
            onSaveCommentEdit={onSaveCommentEdit} />}
        {comments}
      </div>
    </div>
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    ..._.pick(state.readerReducer.ui, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage
  };
};

export default connect(
  mapStateToProps
)(SideBarComments);
