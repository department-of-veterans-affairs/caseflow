// External Dependencies
import { isEqual, findIndex } from 'lodash';

// Local Dependencies
import {
  CATEGORIES,
  ACTION_NAMES,
  INTERACTION_TYPES,
  MOVE_ANNOTATION_ICON_DIRECTIONS,
} from 'store/constants/reader';
import { nextPageCoords, isUserEditingText } from 'utils/reader';
import { stopPlacingAnnotation, showPlaceAnnotationIcon } from 'store/reader/annotationLayer';

/**
 * Helper Method to gather keyboard input from the user
 * @param {Object} state -- The Current Redux Store State
 */
export const annotationListener = ({
  placingAnnotationIconPageCoords,
  isPlacingAnnotation,
  pageDimensions,
  showPdf,
  documents,
  docId,
  dispatch
}) => (event) => {
  // Ignore keyboard input if we are editing text
  if (isUserEditingText()) {
    return;
  }

  // Calculate the document index
  const docIndex = findIndex(documents, docId);

  // Set the Selected Document
  const selectedDoc = documents[docId];

  // Set the Previous Document ID
  const prevDoc = documents[docIndex - 1];

  // Set the Next Document
  const nextDoc = documents[docIndex + 1];

  // Set the list of directions from the keyboard event
  const direction = {
    ArrowLeft: MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT,
    ArrowRight: MOVE_ANNOTATION_ICON_DIRECTIONS.RIGHT,
    ArrowUp: MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
    ArrowDown: MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN
  }[event.key];

  // Update the store if placing annotations and do not recognize keyboard input
  if (isPlacingAnnotation && placingAnnotationIconPageCoords && direction >= 0) {
    const { pageIndex, ...origCoords } = placingAnnotationIconPageCoords;
    const constrainedCoords = nextPageCoords(
      direction,
      placingAnnotationIconPageCoords,
      pageDimensions,
      selectedDoc.content_url,
      selectedDoc.rotation
    );

    // Update the Annotation Icon if there are new Coordinates
    if (!isEqual(origCoords, constrainedCoords)) {
      dispatch(showPlaceAnnotationIcon(pageIndex, constrainedCoords));
    }

    // If the user is placing an annotation, we do not also want
    // to be panning around on the page view with the arrow keys.
    event.preventDefault();

    return;
  }

  // Move to the previous document on Arrow Left
  if (event.key === 'ArrowLeft') {
    window.analyticsEvent(
      CATEGORIES.VIEW_DOCUMENT_PAGE,
      ACTION_NAMES.VIEW_PREVIOUS_DOCUMENT,
      INTERACTION_TYPES.KEYBOARD_SHORTCUT
    );
    showPdf(documents, prevDoc.id);
    dispatch(stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT));
  }

  // Move to the next document on Arrow Right
  if (event.key === 'ArrowRight') {
    window.analyticsEvent(
      CATEGORIES.VIEW_DOCUMENT_PAGE,
      ACTION_NAMES.VIEW_NEXT_DOCUMENT,
      INTERACTION_TYPES.KEYBOARD_SHORTCUT
    );
    showPdf(documents, nextDoc.id);
    stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);

  }
};
