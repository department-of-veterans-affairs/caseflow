// External Dependencies
import { combineReducers } from 'redux';

// Reducers
import pdf from 'store/reader/pdf';
import pdfSearch from 'store/reader/pdfSearch';
import caseSelect from 'store/reader/caseSelect';
import documentList from 'store/reader/documentList';
import pdfViewer from 'store/reader/pdfViewer';
import documents from 'store/reader/documents';
import annotationLayer from 'store/reader/annotationLayer';

/**
 * Root Reader Reducer
 */
const readerReducer = combineReducers({
  caseSelect,
  pdf,
  pdfSearch,
  documents,
  documentList,
  pdfViewer,
  annotationLayer
});

/**
 * Default export wraps the reducer in an HOC for capturing metrics
 */
export default readerReducer;
