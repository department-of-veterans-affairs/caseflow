import { css } from 'glamor';
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

const DIV_STYLING = css({
  width: '100%',
  height: '100%',
  zIndex: 10,
  position: 'relative',
});

const Layer = (props) => {
  const { zoomLevel, pageNumber, documentId, rotation, children } = props;

  const scale = zoomLevel / 100.0;
  const rotationDegrees = Number(rotation.replace('deg', ''));

  const annotations = useSelector((state) => annotationsForDocumentIdAndPageId(state, documentId, pageNumber));
  const allAnnotations = useSelector((state) => annotationsForDocumentId(state, documentId));
  const { placedButUnsavedAnnotation, isPlacingAnnotation, placingAnnotationIconPageCoords } = useSelector(
    annotationPlacement
  );
  const layerRef = useRef(null);
  const dispatch = useDispatch();

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
      scale,
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
      scale,
      rotationDegrees
    );

    dispatch(
      placeAnnotation(
        pageNumber,
        {
          xPosition: x,
          yPosition: y,
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
        scale,
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
        className={DIV_STYLING}
      >
        {children}
        {isPlacingAnnotation && placingAnnotationIconPageCoords?.pageIndex === pageNumber && (
          <Icon
            draggable
            rotation={-rotationDegrees}
            position={placingAnnotationIconPageCoords}
            comment={{}}
            onClick={() => {}}
          />
        )}
        {!isPlacingAnnotation && placedButUnsavedAnnotation && placedButUnsavedAnnotation.page === pageNumber && (
          <Icon
            draggable
            comment={placedButUnsavedAnnotation}
            rotation={-rotationDegrees}
            position={{ x: placedButUnsavedAnnotation.x, y: placedButUnsavedAnnotation.y }}
            onClick={() => {}}
          />
        )}
        {annotations.map((annotation) => (
          <Icon
            key={annotation.uuid}
            draggable
            comment={annotation}
            rotation={-rotationDegrees}
            position={{ x: annotation.x, y: annotation.y }}
            onClick={annotation.isPlacingAnnotation ? () => {} : () => onIconClick(annotation)}
          />
        ))}
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
};

export default Layer;
