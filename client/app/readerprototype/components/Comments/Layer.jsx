import _ from 'lodash';
import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { CATEGORIES, INTERACTION_TYPES } from '../../../reader/analytics';
import {
  placeAnnotation,
  requestMoveAnnotation,
  showPlaceAnnotationIcon,
  startPlacingAnnotation,
  stopPlacingAnnotation,
} from '../../../reader/AnnotationLayer/AnnotationActions';
import { handleSelectCommentIcon } from '../../../reader/PdfViewer/PdfViewerActions';
import { getPageCoordinatesOfMouseEventPrototype } from '../../../reader/utils';
import { annotationPlacement, annotationsForDocumentId, annotationsForDocumentIdAndPageId } from '../../selectors';
import Icon from './Icon';

// This comment provides the framework for positioning, moving and selecting comment icons.
// These icons (in this file referred to as 'annotations') are stored in the database with their positions
// relative to the document scaled to 100% and 0 degrees of rotation. If we scale/rotate the document,
// we have to calculate the mouse position in that transformed frame, use that transformed position for display, but
// ensure we _store_ it without that transformation. Thus, you will see applications of scales/zooms and then see it
// undone upon display.
//
// You will see 3 versions of the comment icon in the render. One is the icon glued to the mouse when
// isPlacingAnnotation is true so the user can see where they are going to position it.
// The second is after they've clicked but haven't saved it yet (ie, they still need to type in their comment)
// The third is the display of the comments already saved that were fetched from the db.
const Layer = (props) => {
  const { zoomLevel, pageNumber, documentId, rotation, children, dimensions } = props;
  const scale = zoomLevel / 100;
  const rotationDegrees = Number(rotation.replace('deg', ''));

  const annotations = useSelector((state) => annotationsForDocumentIdAndPageId(state, documentId, pageNumber));
  const allAnnotations = useSelector((state) => annotationsForDocumentId(state, documentId));
  const { placedButUnsavedAnnotation, isPlacingAnnotation, placingAnnotationIconPageCoords } = useSelector(
    annotationPlacement
  );
  const layerRef = useRef(null);
  const dispatch = useDispatch();

  const commentLayerStyle = {
    width: '100%',
    height: '100%',
    zIndex: 10,
    position: 'relative',
  };

  useEffect(() => {
    const keyHandler = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        if (isPlacingAnnotation) {
          dispatch(stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT));
        }
      }

      if (event.altKey && event.code === 'KeyC') {
        dispatch(startPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT));
      }

      if (event.altKey && event.code === 'Enter') {
        if (isPlacingAnnotation && placingAnnotationIconPageCoords) {
          dispatch(
            placeAnnotation(
              pageNumber,
              {
                xPosition: placingAnnotationIconPageCoords.x,
                yPosition: placingAnnotationIconPageCoords.y,
              },
              documentId
            )
          );
        }
      }
    };

    window.addEventListener('keydown', keyHandler);

    return () => window.removeEventListener('keydown', keyHandler);
  }, [isPlacingAnnotation, placingAnnotationIconPageCoords]);

  const onPageDragOver = (event) => {
    event.preventDefault();
  };
  const onCommentDrop = (event) => {
    const dragAndDropPayload = event.dataTransfer.getData('text');

    // Fix for Firefox browsers. Need to call preventDefault() so that
    // Firefox does not navigate to anything.com.
    // Issue 2969
    event.preventDefault();

    let dragAndDropData;

    // Anything can be dragged and dropped. If the item that was
    // dropped doesn't match what we expect, we just silently ignore it.
    const logInvalidDragAndDrop = () => window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'invalid-drag-and-drop');

    try {
      dragAndDropData = JSON.parse(dragAndDropPayload);

      if (!dragAndDropData.iconCoordinates || !dragAndDropData.uuid) {
        logInvalidDragAndDrop();

        return;
      }
    } catch (err) {
      if (err instanceof SyntaxError) {
        logInvalidDragAndDrop();

        return;
      }
      throw err;
    }
    const coordinates = getPageCoordinatesOfMouseEventPrototype(
      event,
      layerRef.current?.getBoundingClientRect(),
      1,
      rotationDegrees
    );

    const droppedAnnotation = {
      ...allAnnotations.find((annotation) => annotation.uuid === dragAndDropData.uuid),
      ...coordinates,
      page: pageNumber,
    };

    dispatch(requestMoveAnnotation(droppedAnnotation));
  };

  const onPageClick = (event) => {
    if (!isPlacingAnnotation) {
      return;
    }
    const { x, y } = getPageCoordinatesOfMouseEventPrototype(
      event,
      layerRef.current?.getBoundingClientRect(),
      1,
      rotationDegrees
    );

    dispatch(
      placeAnnotation(
        pageNumber,
        {
          xPosition: x / scale,
          yPosition: y / scale,
        },
        documentId
      )
    );
  };
  const mouseListener = (event) => {
    if (isPlacingAnnotation) {
      const pageCoords = getPageCoordinatesOfMouseEventPrototype(
        event,
        layerRef.current?.getBoundingClientRect(),
        1,
        rotationDegrees
      );

      dispatch(showPlaceAnnotationIcon(pageNumber, pageCoords));
    }
  };

  const onIconClick = (annotation) => dispatch(handleSelectCommentIcon(annotation));

  return (
    <div className={`cf-pdf-annotationLayer ${isPlacingAnnotation ? 'cf-pdf-placing-comment' : ''}`}>
      <div
        id={`comment-layer-${pageNumber}`}
        onDragOver={onPageDragOver}
        onDrop={onCommentDrop}
        onClick={onPageClick}
        onMouseMove={mouseListener}
        ref={layerRef}
        style={commentLayerStyle}
      >
        {children}
        <div
          style={{
            position: 'relative',
            top: dimensions.offsetY,
            left: dimensions.offsetX,
            rotate: rotation,
            width: `${dimensions.width}px`,
            height: `${dimensions.height}px`,
            pointerEvents: 'none',
          }}
        >
          {isPlacingAnnotation && placingAnnotationIconPageCoords?.pageIndex === pageNumber && (
            <Icon
              draggable
              rotation={-rotationDegrees}
              position={{
                x: placingAnnotationIconPageCoords.x,
                y: placingAnnotationIconPageCoords.y,
                pageIndex: placingAnnotationIconPageCoords.pageIndex,
              }}
              comment={{}}
              onClick={_.noop}
            />
          )}
          {!isPlacingAnnotation && placedButUnsavedAnnotation && placedButUnsavedAnnotation.page === pageNumber && (
            <Icon
              draggable
              comment={placedButUnsavedAnnotation}
              rotation={-rotationDegrees}
              position={{ x: placedButUnsavedAnnotation.x * scale, y: placedButUnsavedAnnotation.y * scale }}
              onClick={_.noop}
            />
          )}
          {annotations.map((annotation) => (
            <Icon
              key={annotation.uuid}
              draggable
              comment={annotation}
              rotation={-rotationDegrees}
              position={{ x: annotation.x * scale, y: annotation.y * scale }}
              onClick={annotation.isPlacingAnnotation ? _.noop : () => onIconClick(annotation)}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

Layer.propTypes = {
  zoomLevel: PropTypes.number,
  pageNumber: PropTypes.number,
  isVisible: PropTypes.bool,
  documentId: PropTypes.number,
  rotation: PropTypes.string,
  children: PropTypes.element,
  dimensions: PropTypes.object,
};

export default Layer;
