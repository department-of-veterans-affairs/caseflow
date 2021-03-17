// External Dependencies
import { combineReducers } from 'redux';

// Reducers
import appeal from 'store/reader/appeal';
import documentList from 'store/reader/documentList';
import documentViewer from 'store/reader/documentViewer';
import annotationLayer from 'store/reader/annotationLayer';

/**
 * Root Reader Reducer
 */
const readerReducer = combineReducers({
  appeal,
  documentViewer,
  documentList,
  annotationLayer
});

/**
 * Default export wraps the reducer in an HOC for capturing metrics
 */
export default readerReducer;
