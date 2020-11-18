// External Dependencies
import { combineReducers } from 'redux';

// Reducers
import pdf from 'store/reader/pdf';
import pdfSearch from 'store/reader/pdfSearch';
import appeal from 'store/reader/appeal';
import documentList from 'store/reader/documentList';
import pdfViewer from 'store/reader/pdfViewer';
import documentViewer from 'store/reader/documentViewer';
import annotationLayer from 'store/reader/annotationLayer';

/**
 * Root Reader Reducer
 */
const readerReducer = combineReducers({
  appeal,
  pdf,
  pdfSearch,
  documentViewer,
  documentList,
  pdfViewer,
  annotationLayer
});

/**
 * Default export wraps the reducer in an HOC for capturing metrics
 */
export default readerReducer;
