import sinon from 'sinon';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

let numPages = 3;

export default {
  numPages,
  pdfDocument: { pdfInfo: { numPages } },

  beforeEach() {
    // We return a pdfInfo object that contains
    // a field numPages.
    let getDocument = sinon.stub(PDFJS, 'getDocument');
    getDocument.resolves(this.pdfDocument);
  },

  afterEach() {
    PDFJS.getDocument.restore();
  }
};
