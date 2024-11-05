import { combineReducers } from 'redux';
import { timeFunction } from '../util/PerfDebug';

import pdfReducer from './Pdf/PdfReducer';
import searchActionReducer from './PdfSearch/PdfSearchReducer';
import caseSelectReducer from './CaseSelect/CaseSelectReducer';
import documentListReducer from './DocumentList/DocumentListReducer';
import pdfViewerReducer from './PdfViewer/PdfViewerReducer';
import documentsReducer from './Documents/DocumentsReducer';
import annotationLayerReducer from './AnnotationLayer/AnnotationLayerReducer';

export const rootReducer = combineReducers({
  caseSelect: caseSelectReducer,
  pdf: pdfReducer,
  searchActionReducer,
  documents: documentsReducer,
  documentList: documentListReducer,
  pdfViewer: pdfViewerReducer,
  annotationLayer: annotationLayerReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
