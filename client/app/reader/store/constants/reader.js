import React from 'react';

// Local Dependencies
import { CategoryIcon } from 'app/components/icons/CategoryIcon';

export const CATEGORIES = {
  VIEW_DOCUMENT_PAGE: 'Document Viewer',
  CLAIMS_FOLDER_PAGE: 'Claims Folder',
  CASE_SELECTION_PAGE: 'Case Selection'
};

export const ACTION_NAMES = {
  VIEW_NEXT_DOCUMENT: 'view-next-document',
  VIEW_PREVIOUS_DOCUMENT: 'view-previous-document'
};

export const INTERACTION_TYPES = {
  VISIBLE_UI: 'visible-ui',
  KEYBOARD_SHORTCUT: 'keyboard-shortcut'
};

export const ENDPOINT_NAMES = {
  DOCUMENT: 'document',
  ANNOTATION: 'annotation',
  MARK_DOC_AS_READ: 'mark-doc-as-read',
  TAG: 'tag',
  APPEAL_DETAILS: 'appeal-details',
  APPEAL_DETAILS_BY_VET_ID: 'appeal-details-by-vet-id',
  CLAIMS_FOLDER_SEARCHES: 'claims-folder-searches',
  DOCUMENTS: 'documents'
};

export const COMMENT_ACCORDION_KEY = 'Comments';

// If we used CSS in JS, we wouldn't have to keep this value in sync with the CSS in a brittle way.
export const ANNOTATION_ICON_SIDE_LENGTH = 40;

// Arrange the directions such that each direction + 1 modulo 4 rotates clockwise.
export const MOVE_ANNOTATION_ICON_DIRECTIONS = {
  ArrowUp: 0,
  ArrowRight: 1,
  ArrowDown: 2,
  ArrowLeft: 3
};

// An array with the directions oriented in a clockwise rotation.
export const MOVE_ANNOTATION_ICON_DIRECTION_ARRAY = [
  MOVE_ANNOTATION_ICON_DIRECTIONS.ArrowUp,
  MOVE_ANNOTATION_ICON_DIRECTIONS.ArrowRight,
  MOVE_ANNOTATION_ICON_DIRECTIONS.ArrowDown,
  MOVE_ANNOTATION_ICON_DIRECTIONS.ArrowLeft
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

export const DOCUMENTS_OR_COMMENTS_ENUM = {
  DOCUMENTS: 'documents',
  COMMENTS: 'comments'
};

// Rotation Constants
export const ROTATION_INCREMENTS = 90;
export const COMPLETE_ROTATION = 360;

// Documents Table Constants
export const NUMBER_OF_COLUMNS = 6;

// PDF Viewer Constatns
export const NUMBER_OF_DIRECTIONS = 4;

// Zoom Constants
export const ZOOM_RATE = 0.3;
export const MINIMUM_ZOOM = 0.1;

export const LOADING_DATA_MESSAGE = 'Loading claims folder in Reader...';

// Set the cache timeout
export const CACHE_TIMEOUT_HOURS = 3;

export const COMMENT_SCROLL_FROM_THE_TOP = 50;
