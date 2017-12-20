import { combineReducers } from 'redux';

import pdfReducer from './Pdf/PdfReducer';
import searchActionReducer from './PdfSearch/PdfSearchReducer';
import caseSelectReducer from './CaseSelect/CaseSelectReducer';
import documentListReducer from './DocumentList/DocumentListReducer';
import pdfViewerReducer from './PdfViewer/PdfViewerReducer';
import documentsReducer from './Documents/DocumentsReducer';
import annotationLayerReducer from './AnnotationLayer/AnnotationLayerReducer';
import { reducer as searchReducer } from 'redux-search';

const rootReducer = combineReducers({
  caseSelect: caseSelectReducer,
  pdf: pdfReducer,
  search: searchReducer,
  searchActionReducer,
  documents: documentsReducer,
  documentList: documentListReducer,
  pdfViewer: pdfViewerReducer,
  annotationLayer: annotationLayerReducer
});

export default rootReducer;
