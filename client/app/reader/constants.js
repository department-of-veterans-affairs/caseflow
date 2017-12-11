import { CategoryIcon } from '../components/RenderFunctions';
import React from 'react';

// actions
export const RECEIVE_ANNOTATIONS = 'RECEIVE_ANNOTATIONS';
export const RECEIVE_APPEAL_DETAILS = 'RECEIVE_APPEAL_DETAILS';
export const RECEIVE_APPEAL_DETAILS_FAILURE = 'RECEIVE_APPEAL_DETAILS_FAILURE';
export const REQUEST_INITIAL_DATA_FAILURE = 'INITIAL_DATA_LOADING_FAIL';
export const REQUEST_INITIAL_CASE_FAILURE = 'INITIAL_CASE_LOADING_FAIL';

export const SHOW_NEXT_PDF = 'SHOW_NEXT_PDF';
export const SHOW_PREV_PDF = 'SHOW_PREV_PDF';
export const SCROLL_TO_COMMENT = 'SCROLL_TO_COMMENT';
export const TOGGLE_PDF_SIDEBAR = 'TOGGLE_PDF_SIDEBAR';
export const TOGGLE_SEARCH_BAR = 'TOGGLE_SEARCH_BAR';
export const SHOW_SEARCH_BAR = 'SHOW_SEARCH_BAR';
export const HIDE_SEARCH_BAR = 'HIDE_SEARCH_BAR';
export const SCROLL_TO_SIDEBAR_COMMENT = 'SCROLL_TO_SIDEBAR_COMMENT';
export const COLLECT_ALL_TAGS_FOR_OPTIONS = 'COLLECT_ALL_TAGS_FOR_OPTIONS';
export const SET_DOC_SCROLL_POSITION = 'SET_DOC_SCROLL_POSITION';
export const JUMP_TO_PAGE = 'JUMP_TO_PAGE';
export const RESET_JUMP_TO_PAGE = 'RESET_JUMP_TO_PAGE';

export const SET_PAGE_COORD_BOUNDS = 'SET_PAGE_COORD_BOUNDS';
export const SET_UP_PAGE_DIMENSIONS = 'SET_UP_PAGE_DIMENSIONS';
export const SET_PDF_DOCUMENT = 'SET_PDF_DOCUMENT';
export const CLEAR_PDF_DOCUMENT = 'CLEAR_PDF_DOCUMENT';
export const GET_DOCUMENT_TEXT = 'GET_DCOUMENT_TEXT';
export const ZERO_SEARCH_INDEX = 'ZERO_SEARCH_INDEX';
export const UPDATE_SEARCH_INDEX = 'UPDATE_SEARCH_INDEX';
export const SET_SEARCH_INDEX = 'SET_SEARCH_INDEX';
export const SET_SEARCH_INDEX_TO_HIGHLIGHT = 'SET_SEARCH_INDEX_TO_HIGHLIGHT';
export const SET_DOCUMENT_LOAD_ERROR = 'SET_DOCUMENT_LOAD_ERROR';
export const CLEAR_DOCUMENT_LOAD_ERROR = 'CLEAR_DOCUMENT_LOAD_ERROR';
export const SET_LOADED_APPEAL_ID = 'SET_LOADED_APPEAL_ID';

export const SET_OPENED_ACCORDION_SECTIONS = 'SET_OPENED_ACCORDION_SECTIONS';

export const COMMENT_ACCORDION_KEY = 'Comments';

// If we used CSS in JS, we wouldn't have to keep this value in sync with the CSS in a brittle way.
export const ANNOTATION_ICON_SIDE_LENGTH = 40;

export const COMPLETE_ROTATION = 360;

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

// colors
export const READER_COLOR = '#417505';

// UI Text
export const NO_ISSUES_ON_APPEAL_MSG = 'No issues on appeal';

// These both come from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
export const PDF_PAGE_WIDTH = 816;
export const PDF_PAGE_HEIGHT = 1056;

// errors
export const SHOW_ERROR_MESSAGE = 'SHOW_ERROR_MESSAGE';
export const HIDE_ERROR_MESSAGE = 'HIDE_ERROR_MESSAGE';
export const RESET_PDF_SIDEBAR_ERRORS = 'RESET_PDF_SIDEBAR_ERRORS';

// Defined in _search_bar.scss > .cf-search-bar. Max height of
// search bar, used as offset when scrolling to search results
export const SEARCH_BAR_HEIGHT = 50;
