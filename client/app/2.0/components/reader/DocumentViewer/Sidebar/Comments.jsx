// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { EditComment } from 'components/reader/DocumentViewer/Sidebar/EditComment';
import { CannotSaveAlert } from 'components/reader/DocumentViewer/CannotSaveAlert';
import { plusIcon } from 'app/components/RenderFunctions';
import Button from 'app/components/Button';
import { Comment } from 'components/reader/DocumentViewer/Sidebar/Comment';

/**
 * Sidebar Comment Component for Document Screen
 * @param {Object} props --  Contains details about the comments and managing comments
 */
export const SidebarComments = ({
  comments,
  addComment,
  placedButUnsavedAnnotation,
  error,
  createAnnotation,
  updateAnnotationContent,
  updateAnnotationRelevantDate,
  stopPlacingAnnotation,
  cancelEditAnnotation,
  requestEditAnnotation,
  handleClick,
  commentRef,
  selectedAnnotationId,
  currentDocument,
  ...props
}) => (
  <div>
    <span className="cf-right-side cf-add-comment-button">
      <Button name="AddComment" onClick={addComment} >
        <span>{plusIcon()}&nbsp; Add a comment</span>
      </Button>
    </span>
    <div style={{ clear: 'both' }}></div>
    <div className="cf-comment-wrapper">
      {error?.annotation?.visible && <CannotSaveAlert message={error.annotation.message} />}
      <div className="cf-pdf-comment-list">
        {placedButUnsavedAnnotation && (
          <EditComment
            comment={placedButUnsavedAnnotation}
            id="addComment"
            disableOnEmpty
            onChange={updateAnnotationContent}
            onChangeDate={updateAnnotationRelevantDate}
            onCancelCommentEdit={stopPlacingAnnotation}
            onSaveCommentEdit={createAnnotation}
          />
        )}
        {comments.map((comment, index) => (
          <React.Fragment key={index}>
            {comment.editing ? (
              <EditComment
                id={`editCommentBox-${comment.temporaryId || comment.id}`}
                comment={comment}
                onCancelCommentEdit={cancelEditAnnotation}
                onChange={updateAnnotationContent}
                onChangeDate={updateAnnotationRelevantDate}
                value={comment.comment}
                onSaveCommentEdit={requestEditAnnotation}
                key={comment.temporaryId || comment.id}
              />
            ) : (
              <div ref={commentRef} key={comment.temporaryId || comment.id}>
                <Comment
                  id={`comment${index}`}
                  comment={comment}
                  selected={comment.id === selectedAnnotationId}
                  handleClick={handleClick}
                  page={comment.page}
                  date={comment.relevant_date}
                  currentDocument={currentDocument}
                  {...props}
                >
                  {comment.comment}
                </Comment>
              </div>
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  </div>
);

SidebarComments.propTypes = {
  currentDocument: PropTypes.object,
  comments: PropTypes.array,
  addComment: PropTypes.func,
  placedButUnsavedAnnotation: PropTypes.func,
  error: PropTypes.object,
  createAnnotation: PropTypes.func,
  updateAnnotationContent: PropTypes.func,
  updateAnnotationRelevantDate: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  cancelEditAnnotation: PropTypes.func,
  requestEditAnnotation: PropTypes.func,
  handleClick: PropTypes.func,
  commentRef: PropTypes.element,
  startEditAnnotation: PropTypes.func,
  selectedAnnotationId: PropTypes.number,
};
