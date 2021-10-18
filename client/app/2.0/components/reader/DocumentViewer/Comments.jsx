// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import { commentIcon } from 'app/components/RenderFunctions';
import { commentStyles, selectionStyles } from 'styles/reader/Document/Comments';

/**
 * Comments component for the Document Screen
 * @param {Object} props --  Contains details about dragging/dropping comments and position
 */
export const Comments = ({
  pageIndex,
  movingComment,
  moveMouse,
  dropComment,
  commentsRef,
  comments,
  handleDrop,
  currentDocument,
  selectedComment,
  textLayerRef,
  startMove,
  selectComment,
  getCoords,
  ...props
}) => {
  useEffect(() => {
    // Handle document search position
    if (props.search.scrollPosition) {
      props.gridRef.current?.scrollToPosition({
        scrollTop: props.search.scrollPosition,
      });
    }
  }, [props.search.scrollPosition]);

  return (
    <div
      id={`comment-layer-${pageIndex}`}
      key={pageIndex}
      style={commentStyles}
      onDragOver={(event) => event.preventDefault()}
      onClick={(event) => {
        // Prevent the drop comment from bubbling events
        event.stopPropagation();

        // Drop the comment
        dropComment(getCoords(event, pageIndex), pageIndex);
      }}
      onMouseMove={moveMouse}
      ref={commentsRef}
      onDrop={handleDrop}
    >
      {comments.filter((comment) => comment.page === pageIndex + 1).map((comment) => (
        <div
          id={`commentIcon-container-${comment.id}`}
          className="commentIcon-container"
          key={comment.id}
          data-placing-annotation-icon={comment.dropping}
          onClick={movingComment ? null : () => selectComment(comment)}
          onDragStart={() => startMove(comment.id)}
          style={{
            left: comment.x * props.scale,
            top: comment.y * props.scale,
            transform: `rotate(${currentDocument.rotation}deg)`,
            cursor: movingComment === comment.id ? 'grabbing' : 'pointer',
          }}
          draggable
        >
          {commentIcon(selectedComment?.id === comment?.id, comment?.id)}
        </div>
      ))}
      <div
        {...selectionStyles}
        id={`text-${pageIndex}`}
        ref={textLayerRef}
        className="cf-pdf-pdfjs-textLayer"
      />
    </div>
  );
};

Comments.propTypes = {
  comments: PropTypes.array,
  pageIndex: PropTypes.number,
  file: PropTypes.string,
  movingComment: PropTypes.number,
  handleDrop: PropTypes.func,
  moveMouse: PropTypes.func,
  dropComment: PropTypes.func,
  getCoords: PropTypes.func,
  commentsRef: PropTypes.element,
  isVisible: PropTypes.bool,
  onDrag: PropTypes.func,
  position: PropTypes.number,
  currentDocument: PropTypes.object,
  selectedComment: PropTypes.object,
  textLayerRef: PropTypes.element,
  scale: PropTypes.number,
  dimensions: PropTypes.shape({
    width: PropTypes.number,
    height: PropTypes.number,
  }),
  startMove: PropTypes.func,
  selectComment: PropTypes.func,
  search: PropTypes.object,
  gridRef: PropTypes.object,
};
