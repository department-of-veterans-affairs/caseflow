import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import Pdf from '../../app/components/Pdf';
import sinon from 'sinon';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

/* eslint-disable no-unused-expressions */
describe('Pdf', () => {
  let pdfId = "pdf";

  // Note, these tests use mount rather than shallow.
  // In order to get that working, we must stub out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // To appraoch reality, our stubbed out versions
  // also add divs representing PDF 'pages' to the dom.

  /* eslint-disable max-statements */
  context('mount and mock out pdfjs', () => {
    let wrapper;
    let renderPage;
    let createPage;
    let onPageChange;
    let numPages = 3;

    beforeEach(() => {
      // We return a pdfInfo object that contains
      // a field numPages.
      let getDocument = sinon.stub(PDFJS, 'getDocument');

      getDocument.resolves({ pdfInfo: { numPages } });

      // We return a promise that resolves to an object
      // with a getViewport function.
      renderPage = sinon.stub(PDFJSAnnotate.UI, 'renderPage');
      renderPage.resolves([
        {
          getViewport: () => 0
        }
      ]);

      // We return fake 'page' divs that the PDF component
      // will add to the dom.
      createPage = sinon.stub(PDFJSAnnotate.UI, 'createPage');
      createPage.callsFake((index) => {
        let div = document.createElement("div");

        div.id = `pageContainer${index}`;

        return div;
      });

      onPageChange = sinon.spy();

      wrapper = mount(<Pdf
        documentId={1}
        file="test.pdf"
        id={pdfId}
        pdfWorker="noworker"
        scale={1}
      />, { attachTo: document.getElementById('app') });
    });

    afterEach(() => {
      PDFJS.getDocument.restore();
      PDFJSAnnotate.UI.renderPage.restore();
      PDFJSAnnotate.UI.createPage.restore();
    });

    context('.render', () => {
      it(`renders the staging div`, () => {
        expect(wrapper.find(`#${pdfId}`)).to.have.length(1);
      });
    });

    // This tests what happens when we first mount the component
    // This also tests the methods '.draw', and '.createPages'
    context('.componentDidMount', () => {
      it(`only renders the first page`, () => {
        expect(renderPage.callCount).to.equal(1);
      });

      it(`calls onPageChange with page Numbers`, () => {
        expect(onPageChange.calledWith(1, numPages));
      });
    });

    context('.renderPage', () => {
      it('creates a new page', () => {
        wrapper.instance().renderPage(1);
        expect(renderPage.callCount).to.equal(2);
      });

      it('marks page as rendered', () => {
        expect(wrapper.instance().isRendered[1]).to.be.undefined;
        wrapper.instance().renderPage(1);
        expect(wrapper.instance().isRendered[1]).to.be.true;
      });

      context('mock renderPage to fail', () => {
        beforeEach(() => {
          renderPage.resetBehavior();
          renderPage.rejects();
        });

        // it('does not mark page as rendered', () => {
        //   expect(wrapper.instance().isRendered[1]).to.be.undefined;
        //   console.log(wrapper.instance().isRendered[1]);
        //   wrapper.instance().renderPage(1);
        //   expect(wrapper.instance().isRendered[1]).should.eventually.be.false;
        // });
      });
    });

    context('.componentWillReceiveProps', () => {
      let draw;

      beforeEach(() => {
        draw = sinon.spy(wrapper.instance(), 'setupPdf');
      });

      context('when file is set', () => {
        it('creates a new page', () => {
          wrapper.setProps({ file: 'newFile' });
          expect(draw.callCount).to.equal(1);
        });
      });

      context('when scale is set', () => {
        it('creates a new page', () => {
          wrapper.setProps({ scale: 2 });
          expect(draw.callCount).to.equal(1);
        });
      });
    });

    context('.onPageClick', () => {
      context('supplied with props.onPageClick', () => {
        let onPageClick;

        beforeEach(() => {
          onPageClick = sinon.spy();
          wrapper.setProps({
            onPageClick,
            scale: 2
          });
        });

        it('calls onPageClick prop', () => {
          let event = {
            offsetX: 10,
            offsetY: 10,
            target: {
              offsetLeft: 20,
              offsetTop: 30
            }
          };

          // The expected coordinate is
          // (( offsetX + offsetLeft ) / 2, (offsetY + offsetTop) / 2)
          // (( 10 + 20) / 2, (10 + 30) / 2)
          // (15, 20)
          let coordinate = {
            xPosition: 15,
            yPosition: 20
          };

          wrapper.instance().onPageClick('viewport', 0)(event);
          expect(onPageClick.calledWith('viewport', 0, coordinate)).to.be.true;
        });
      });
    });
  });
  /* eslint-enable max-statements */
});
/* eslint-enable no-unused-expressions */
