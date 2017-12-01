import sinon from 'sinon';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

const numPages = 3;

export const PAGE_WIDTH = 100;
export const PAGE_HEIGHT = 200;

export default {
  numPages,
  pdfDocument: {
    pdfInfo: {
      numPages
    },
    getPage: sinon.stub().resolves({
      getViewport: () => ({ width: PAGE_WIDTH,
        height: PAGE_HEIGHT }),
      transport: {
        destroyed: false
      },
      getTextContent: sinon.stub().resolves('hello world'),
      cleanup: sinon.stub(),
      render: sinon.stub().resolves()
    }),
    destroy: sinon.stub(),
    transport: {
      destroyed: false
    }
  },

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
