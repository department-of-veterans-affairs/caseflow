// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import { noop } from 'lodash';

// Internal Dependencies
import { commentIcon } from 'app/components/RenderFunctions';
import { commentStyles, selectionStyles, textLayerStyles } from 'styles/reader/Document/Comments';

/**
 * Comments component for the Document Screen
 * @param {Object} props --  Contains details about dragging/dropping comments and position
 */
export const Comments = ({
  pageIndex,
  file,
  dragOverPage,
  dropComment,
  moveMouse,
  clickPage,
  commentsRef,
  isVisible,
  comments,
  onDrag,
  currentDocument,
  selected,
  textLayerRef,
  startDrag,
  selectComment,
  ...props
}) => {
  useEffect(() => {
    if (props.search.scrollPosition) {
       props.gridRef.current?.scrollToPosition({ scrollTop: props.search.scrollPosition });
    }

  }, [props.search.scrollPosition]);

  return (
    <div
      key={pageIndex}
      id={`comment-layer-${pageIndex}-${file}`}
      style={commentStyles}
      onDragOver={dragOverPage}
      onDrop={dropComment}
      onClick={clickPage}
      onMouseMove={moveMouse}
      ref={commentsRef}
    >
      {isVisible && comments.map((comment) => (
        <div
          key={comment.id}
          style={{
            left: comment.x,
            top: comment.y,
            transform: `rotate(${currentDocument.rotation}deg)`,
            cursor: 'pointer'
          }}
          data-placing-annotation-icon={comment.isPlacingAnnotationIcon}
          className="commentIcon-container"
          id={`commentIcon-container-${comment.uuid}`}
          onClick={() => selectComment(comment)}
          draggable={onDrag !== null}
          onDragStart={startDrag}
        >
          {commentIcon(selected, comment.uuid)}
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
  clickPage: PropTypes.func,
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
    height: PropTypes.number
  }),
  startDrag: PropTypes.func,
  selectComment: PropTypes.func
};
