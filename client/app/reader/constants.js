import { CategoryIcon } from '../components/icons/CategoryIcon';
import React from 'react';

// If we used CSS in JS, we wouldn't have to keep this value in sync with the CSS in a brittle way.
export const ANNOTATION_ICON_SIDE_LENGTH = 40;

// Arrange the directions such that each direction + 1 modulo 4 rotates clockwise.
export const MOVE_ANNOTATION_ICON_DIRECTIONS = {
  UP: 0,
  RIGHT: 1,
  DOWN: 2,
  LEFT: 3
};

// An array with the directions oriented in a clockwise rotation.
export const MOVE_ANNOTATION_ICON_DIRECTION_ARRAY = [
  MOVE_ANNOTATION_ICON_DIRECTIONS.UP,
  MOVE_ANNOTATION_ICON_DIRECTIONS.RIGHT,
  MOVE_ANNOTATION_ICON_DIRECTIONS.DOWN,
  MOVE_ANNOTATION_ICON_DIRECTIONS.LEFT
];

export const documentCategories = {
  procedural: {
    renderOrder: 0,
    humanName: 'Procedural',
    svg: <CategoryIcon color="#5A94EC" />
  },
  medical: {
    renderOrder: 1,
    humanName: 'Medical',
    svg: <CategoryIcon color="#FF6868" />
  },
  other: {
    renderOrder: 2,
    humanName: 'Other Evidence',
    svg: <CategoryIcon color="#3AD2CF" />
  },
  case_summary: {
    renderOrder: 3,
    humanName: 'Case Summary',
    svg: <CategoryIcon color="#FDC231" />,
    readOnly: true
  }
};

// UI Text
export const NO_ISSUES_ON_APPEAL_MSG = 'No issues on appeal';

// These both come from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
export const PDF_PAGE_WIDTH = 816;
export const PDF_PAGE_HEIGHT = 1056;

// Defined in _search_bar.scss > .cf-search-bar. Max height of
// search bar, used as offset when scrolling to search results
export const SEARCH_BAR_HEIGHT = 50;

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
export const PAGE_MARGIN = 25;

// Base scale used to calculate dimensions and draw text.
export const PAGE_DIMENSION_SCALE = 1;
