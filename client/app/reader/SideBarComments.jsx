import React, { PureComponent } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import EditComment from './EditComment';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { plusIcon } from '../components/RenderFunctions';
import Button from '../components/Button';
import _ from 'lodash';
import { INTERACTION_TYPES } from './analytics';
<<<<<<< HEAD

import { updateNewAnnotationContent, createAnnotation, stopPlacingAnnotation,
  startPlacingAnnotation } from '../reader/actions';
=======
import { createAnnotation, stopPlacingAnnotation,
  startPlacingAnnotation, updateNewAnnotationContent
} from '../reader/PdfViewer/AnnotationActions';
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b

class SideBarComments extends PureComponent {
  handleAddClick = (event) => {
    this.props.startPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
    event.stopPropagation();
  }

  stopPlacingAnnotation = () => this.props.stopPlacingAnnotation('from-canceling-new-annotation');

  render() {
    let {
      comments
    } = this.props;

    return <div>
      <span className="cf-right-side cf-add-comment-button">
        <Button
          name="AddComment"
          onClick={this.handleAddClick}>
          <span>{ plusIcon() } &nbsp; Add a comment</span>
        </Button>
      </span>
<<<<<<< HEAD
    <div id="cf-comment-wrapper" className="cf-comment-wrapper">
      {this.props.showErrorMessage.annotation && <CannotSaveAlert />}
      <div className="cf-pdf-comment-list">
        {this.props.placedButUnsavedAnnotation &&
          <EditComment
            comment={this.props.placedButUnsavedAnnotation}
            id="addComment"
            disableOnEmpty={true}
            onChange={this.props.updateNewAnnotationContent}
            onCancelCommentEdit={this.stopPlacingAnnotation}
            onSaveCommentEdit={this.props.createAnnotation} />}
        {comments}
      </div>
    </div>
=======
      <div id="cf-comment-wrapper" className="cf-comment-wrapper">
        {this.props.error.annotation.visible && <CannotSaveAlert message={this.props.error.annotation.message} />}
        <div className="cf-pdf-comment-list">
          {this.props.placedButUnsavedAnnotation &&
          <EditComment
            comment={this.props.placedButUnsavedAnnotation}
            id="addComment"
            disableOnEmpty
            onChange={this.props.updateNewAnnotationContent}
            onCancelCommentEdit={this.stopPlacingAnnotation}
            onSaveCommentEdit={this.props.createAnnotation} />}
          {comments}
        </div>
      </div>
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
    </div>;
  }
}

const mapStateToProps = (state) => {
  return {
    ..._.pick(state.readerReducer.ui, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
<<<<<<< HEAD
    showErrorMessage: state.readerReducer.ui.pdfSidebar.showErrorMessage
=======
    error: state.readerReducer.ui.pdfSidebar.error
>>>>>>> 06be805a17ef706c294f809fac882ebfe6c82a5b
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    updateNewAnnotationContent,
    createAnnotation,
    stopPlacingAnnotation,
    startPlacingAnnotation
  }, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SideBarComments);
