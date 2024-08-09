// External Dependencies
import { combineReducers } from 'redux';

// Reducers
import appeal from './appeal';
import documentList from './documentList';
import documentViewer from './documentViewer';
import annotationLayer from './annotationLayer';

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
