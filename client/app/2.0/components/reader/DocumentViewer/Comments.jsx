// External Dependencies
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import querystring from 'querystring';

// Internal Dependencies
import { commentIcon } from 'app/components/RenderFunctions';
import { commentStyles, selectionStyles } from 'styles/reader/Document/Comments';
import { getPageCoordinatesOfMouseEvent } from 'utils/reader';

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
    // Handle document search position
    if (props.search.scrollPosition) {
      props.gridRef.current?.scrollToPosition({
        scrollTop: props.search.scrollPosition,
      });
    }

    // Parse the query to determine if there is an annotation selected
    const query = querystring.parse(window.location.search)['?annotation'];

    // Parse the annotation ID
    const annotationId = query ? parseInt(query, 10) : null;

    // Handle Comment selection position
    if (comments.length && annotationId) {
      // Get the comment from the list
      const [comment] = comments.filter((item) => item.id === annotationId);

      // Ensure the comment exists
      if (comment) {
        // Calculate the coordinates of the comment to jump
        const coords = getPageCoordinatesOfMouseEvent(
          { pageX: comment.x, pageY: comment.y },
          document.getElementById(`comment-layer-${comment.page - 1}`).getBoundingClientRect(),
          props.scale,
          currentDocument.rotation
        );

        // Scroll to the comment
        props.gridRef.current?.scrollToPosition({
          scrollTop: coords.y
        });

        // Update the store with the selected comment
        selectComment(comment);
      }
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
            left: comment.x * props.scale,
            top: comment.y * props.scale,
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
