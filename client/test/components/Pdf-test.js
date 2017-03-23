import React from 'react';
import { expect } from 'chai';
import { shallow, mount } from 'enzyme';
import Pdf from '../../app/components/Pdf';
import sinon from 'sinon';

import PDFJSAnnotate from 'pdf-annotate.js';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

describe.only('Pdf', () => {
  let pdfId = "pdf";

  // Note, these tests use mount rather than shallow
  // in order to get that working, we must mock out
  // our endpoints in PDFJS and PDFJSAnnotate.
  // Unfortunately PDFJS has to add to the DOM outside
  // of our normal React flow. Enzyme only tracks
  // elements that are added within this flow.
  // This means if you want to reference any
  // elements created by our mock'd PDFJS you
  // will have to use document.getElement(s)By...
  context('mount and mock out pdfjs', () => {
    let wrapper;
    let mock;
    let renderPage;
    let createPage;
    let onPageChange;

    let numPages = 3;

    beforeEach(() => {
      let getDocument = sinon.stub(PDFJS, 'getDocument');
      getDocument.resolves({ pdfInfo: { numPages } });

      renderPage = sinon.stub(PDFJSAnnotate.UI, 'renderPage');
      renderPage.resolves([{ getViewport: () => { return 0; } }]);

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
        wrapper.getNode().renderPage(1);
        expect(renderPage.callCount).to.equal(2);
      });

      it('marks page as rendered', () => {
        expect(wrapper.getNode().isRendered[1]).to.be.undefined;
        wrapper.getNode().renderPage(1);
        expect(wrapper.getNode().isRendered[1]).to.be.true;
      });

      context('mock renderPage to fail', () => {
        beforeEach(() => {
          renderPage.resetBehavior();
          renderPage.rejects();
        });

        // it('does not mark page as rendered', () => {
        //   expect(wrapper.getNode().isRendered[1]).to.be.undefined;
        //   console.log(wrapper.getNode().isRendered[1]);
        //   wrapper.getNode().renderPage(1);
        //   expect(wrapper.getNode().isRendered[1]).should.eventually.be.false;
        // });
      });
    });

    context('.componentWillReceiveProps', () => {
      let draw;
      beforeEach(() => {
        draw = sinon.spy(wrapper.getNode(), 'setupPdf');
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
          wrapper.setProps({ onPageClick, scale: 2 });
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

          wrapper.getNode().onPageClick('viewport', 0)(event);
          expect(onPageClick.calledWith('viewport', 0, coordinate)).to.be.true;
        });
      });
    });
  });
});
