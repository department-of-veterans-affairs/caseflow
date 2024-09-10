import React, { PureComponent } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import EditComment from './EditComment';
import CannotSaveAlert from '../reader/CannotSaveAlert';
import { PlusIcon } from '../components/icons/PlusIcon';
import Button from '../components/Button';
import _ from 'lodash';
import { INTERACTION_TYPES } from './analytics';
import {
  createAnnotation,
  stopPlacingAnnotation,
  startPlacingAnnotation,
  updateNewAnnotationContent,
  updateNewAnnotationRelevantDate,
} from '../reader/AnnotationLayer/AnnotationActions';

class SideBarComments extends PureComponent {
  handleAddClick = (event) => {
    this.props.startPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
    event.stopPropagation();
  };

  stopPlacingAnnotation = () => this.props.stopPlacingAnnotation('from-canceling-new-annotation');

  render() {
    let { comments } = this.props;

    return (
      <div>
        <span className="cf-right-side cf-add-comment-button">
          <Button name="AddComment" onClick={this.handleAddClick}>
            <span>
              <PlusIcon size={12} /> &nbsp; Add a comment
            </span>
          </Button>
        </span>
        <div style={{ clear: 'both' }} />
        <div className="cf-comment-wrapper">
          {this.props.error.annotation.visible && <CannotSaveAlert message={this.props.error.annotation.message} />}
          <div className="cf-pdf-comment-list">
            {this.props.placedButUnsavedAnnotation && (
              <EditComment
                comment={this.props.placedButUnsavedAnnotation}
                id="addComment"
                disableOnEmpty
                onChange={this.props.updateNewAnnotationContent}
                onChangeDate={this.props.updateNewAnnotationRelevantDate}
                onCancelCommentEdit={this.stopPlacingAnnotation}
                onSaveCommentEdit={this.props.createAnnotation}
              />
            )}
            {comments}
          </div>
        </div>
      </div>
    );
  }
}

SideBarComments.propTypes = {
  startPlacingAnnotation: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  comments: PropTypes.node,
  error: PropTypes.node,
  placedButUnsavedAnnotation: PropTypes.func,
  updateNewAnnotationContent: PropTypes.func,
  updateNewAnnotationRelevantDate: PropTypes.func,
  createAnnotation: PropTypes.func,
};

const mapStateToProps = (state) => {
  return {
    ..._.pick(state.annotationLayer, 'placedButUnsavedAnnotation', 'selectedAnnotationId'),
    error: state.pdfViewer.pdfSideBarError,
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators(
    {
      updateNewAnnotationContent,
      updateNewAnnotationRelevantDate,
      createAnnotation,
      stopPlacingAnnotation,
      startPlacingAnnotation,
    },
    dispatch
  ),
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SideBarComments);
