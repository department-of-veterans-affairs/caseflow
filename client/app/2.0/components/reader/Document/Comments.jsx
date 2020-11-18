// External Dependencies
import React from 'react';
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
  annotations,
  onDrag,
  currentDocument,
  selected,
  textLayerRef,
  dimensions,
  scale,
  startDrag,
  selectCommentIcon
}) => (
  <div
    id={`comment-layer-${pageIndex}-${file}`}
    style={commentStyles}
    onDragOver={dragOverPage}
    onDrop={dropComment}
    onClick={clickPage}
    onMouseMove={moveMouse}
    ref={commentsRef}
  >
    {isVisible && annotations.map((comment) => (
      <div
        key={comment.uuid}
        style={{ left: comment.x, top: comment.y, transform: `rotate(${currentDocument.rotation}deg)` }}
        data-placing-annotation-icon={comment.isPlacingAnnotationIcon}
        className="commentIcon-container"
        id={`commentIcon-container-${comment.uuid}`}
        onClick={comment.isPlacingAnnotationIcon ? noop : selectCommentIcon}
        draggable={onDrag !== null}
        onDragStart={startDrag}
      >
        {commentIcon(selected, comment.uuid)}
      </div>
    ))}
    <div {...selectionStyles} style={textLayerStyles(dimensions, scale)} ref={textLayerRef} className="textLayer" />
  </div>
);

Comments.propTypes = {
  annotations: PropTypes.array,
  pageIndex: PropTypes.number,
  file: PropTypes.object,
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
  selectCommentIcon: PropTypes.func
};
