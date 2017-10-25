// placeAnnotation, startPlacingAnnotation,
// stopPlacingAnnotation, showPlaceAnnotationIcon,
// onScrollToComment

import * as Constants from './constants';
import { CATEGORIES } from './analytics';

export const placeAnnotation = (pageNumber, coordinates, documentId) => ({
  type: Constants.PLACE_ANNOTATION,
  payload: {
    page: pageNumber,
    x: coordinates.xPosition,
    y: coordinates.yPosition,
    documentId
  }
});

export const startPlacingAnnotation = (interactionType) => ({
  type: Constants.START_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'startplacing-annotation',
      label: interactionType
    }
  }
});

export const stopPlacingAnnotation = (interactionType) => ({
  type: Constants.STOP_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'stopplacingannotation',
      label: interactionType
    }
  }
});

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});
