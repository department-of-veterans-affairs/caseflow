import sinon from 'sinon';
import { PDFJS } from 'pdfjs-dist';

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
    this.getDocument = sinon.stub(PDFJS, 'getDocument');

    this.getDocument.resolves(this.pdfDocument);
  },

  afterEach() {
    this.getDocument.restore();
  }
};
