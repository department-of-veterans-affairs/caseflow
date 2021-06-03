// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Local Dependencies
import { EditComment } from 'components/reader/DocumentViewer/Sidebar/EditComment';
import { CannotSaveAlert } from 'components/shared/CannotSaveAlert';
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
  droppedComment,
  errors,
  updateComment,
  selectComment,
  commentRef,
  selectedComment,
  currentDocument,
  saveComment,
  cancelDrop,
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
      {errors?.comments?.comment?.visible && <CannotSaveAlert message={errors.comments.comment.message} />}
      <div className="cf-pdf-comment-list">
        {droppedComment && (
          <EditComment
            {...props}
            resetEdit={cancelDrop}
            comment={droppedComment}
            nodeId="addComment"
            disableOnEmpty
            onChange={(val) => updateComment({ ...droppedComment, pendingComment: val })}
            changeDate={(val) => updateComment({ ...droppedComment, pendingDate: val })}
            saveComment={() => saveComment(droppedComment, 'create')}
          />
        )}
        {comments.map((comment, index) => comment.id !== droppedComment?.id && (
          <React.Fragment key={index}>
            {comment.editing ? (
              <EditComment
                {...props}
                nodeId={`editCommentBox-${comment.temporaryId || comment.id}`}
                saveComment={() => saveComment(comment)}
                comment={comment}
                onChange={(val) => updateComment({ ...comment, pendingComment: val })}
                changeDate={(val) => updateComment({ ...comment, pendingDate: val })}
                value={comment.comment}
                key={comment.temporaryId || comment.id}
              />
            ) : (
              <div id={`comment${index}`} ref={commentRef} key={comment.temporaryId || comment.id}>
                <Comment
                  {...props}
                  comment={comment}
                  selected={comment?.id === selectedComment?.id}
                  handleClick={(event) => {
                    event.stopPropagation();

                    props.setPageNumber(comment.page - 1);

                    selectComment(comment);

                  }}
                  page={comment.page}
                  date={comment.relevant_date}
                  currentDocument={currentDocument}
                />
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
  setPageNumber: PropTypes.func,
  droppedComment: PropTypes.object,
  errors: PropTypes.object,
  saveComment: PropTypes.func,
  cancelDrop: PropTypes.func,
  updateComment: PropTypes.func,
  updateCommentDate: PropTypes.func,
  selectComment: PropTypes.func,
  commentRef: PropTypes.element,
  selectedComment: PropTypes.object,
};
