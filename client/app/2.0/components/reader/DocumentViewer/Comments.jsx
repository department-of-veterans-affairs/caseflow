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
  onClick,
  commentsRef,
  comments,
  handleDrop,
  currentDocument,
  selected,
  textLayerRef,
  startMove,
  selectComment,
  ...props
}) => {
  useEffect(() => {
    if (props.search.scrollPosition) {
      props.gridRef.current?.scrollToPosition({
        scrollTop: props.search.scrollPosition,
      });
    }
  }, [props.search.scrollPosition]);

  return (
    <div
      key={pageIndex}
      id={`comment-layer-${pageIndex}`}
      style={commentStyles}
      onDragOver={(event) => event.preventDefault()}
      onClick={onClick}
      onMouseMove={moveMouse}
      ref={commentsRef}
      onDrop={handleDrop}
    >
      {comments.map((comment) => (
        <div
          draggable
          key={comment.id}
          style={{
            left: comment.x,
            top: comment.y,
            transform: `rotate(${currentDocument.rotation}deg)`,
            cursor: 'pointer',
          }}
          data-placing-annotation-icon={comment.dropping}
          className="commentIcon-container"
          id={`commentIcon-container-${comment.id}`}
          onClick={movingComment ? null : () => selectComment(comment)}
          onDragStart={() => startMove(comment.id)}
        >
          {commentIcon(selected, comment.id)}
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
  dragOverPage: PropTypes.func,
  dropComment: PropTypes.func,
  moveMouse: PropTypes.func,
  onClick: PropTypes.func,
  commentsRef: PropTypes.element,
  isVisible: PropTypes.bool,
  onDrag: PropTypes.func,
  position: PropTypes.number,
  currentDocument: PropTypes.object,
  selected: PropTypes.bool,
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
