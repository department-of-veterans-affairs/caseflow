import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import Comment from './Comment';
import EditComment from './EditComment';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { plusIcon } from '../components/RenderFunctions';
import Button from '../components/Button';
import _ from 'lodash';

import { updateNewAnnotationContent, selectAnnotation, cancelEditAnnotation,
  updateAnnotationContent, requestEditAnnotation, startEditAnnotation,
  createAnnotation} from '../reader/actions';
import { categoryFieldNameOfCategoryName, keyOfAnnotation, sortAnnotations }
  from './utils';

class SideBarComments extends PureComponent {
  render() {
    let {
      handleAddClick,
      onCancelCommentEdit
    } = this.props;

    let comments = [];

    comments = sortAnnotations(this.props.comments).map((comment, index) => {
      if (comment.editing) {
        return <EditComment
            id={`editCommentBox-${keyOfAnnotation(comment)}`}
            comment={comment}
            onCancelCommentEdit={this.props.cancelEditAnnotation}
            onChange={this.props.updateAnnotationContent}
            value={comment.comment}
            onSaveCommentEdit={this.props.requestEditAnnotation}
            key={keyOfAnnotation(comment)}
          />;
      }

      const handleClick = () => {
        this.props.onJumpToComment(comment)();
        this.props.selectAnnotation(comment.id);
      };

      return <div ref={(commentElement) => {
        this.commentElements[comment.id] = commentElement;
      }}
        key={keyOfAnnotation(comment)}>
        <Comment
          id={`comment${index}`}
          onEditComment={this.props.startEditAnnotation}
          uuid={comment.uuid}
          selected={comment.id === this.props.selectedAnnotationId}
          onClick={handleClick}
          page={comment.page}>
            {comment.comment}
          </Comment>
        </div>;
    });

    return <div>
      <span className="cf-right-side cf-add-comment-button">
        <Button
          name="AddComment"
          onClick={handleAddClick}>
          <span>{ plusIcon() } &nbsp; Add a comment</span>
        </Button>
      </span>
    <div id="cf-comment-wrapper" className="cf-comment-wrapper">
      {this.props.showErrorMessage.annotation && <CannotSaveAlert />}
      <div className="cf-pdf-comment-list">
        {this.props.placedButUnsavedAnnotation &&
          <EditComment
            comment={this.props.placedButUnsavedAnnotation}
            id="addComment"
            disableOnEmpty={true}
            onChange={this.props.updateNewAnnotationContent}
            onCancelCommentEdit={onCancelCommentEdit}
            onSaveCommentEdit={this.props.createAnnotation} />}
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

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    updateNewAnnotationContent,
    selectAnnotation,
    cancelEditAnnotation,
    updateAnnotationContent,
    requestEditAnnotation,
    startEditAnnotation
  }, dispatch)
})

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SideBarComments);
