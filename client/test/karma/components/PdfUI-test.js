import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { PdfUI } from '../../../app/components/PdfUI';
import sinon from 'sinon';

const DOCUMENT_PATH_BASE = '/reader/appeal/reader_id1';

/* eslint-disable no-unused-expressions */
describe('PdfUI', () => {
  context('shallow create PdfUI', () => {
    let wrapper;
    let doc;

    beforeEach(() => {
      doc = {
        filename: 'My PDF',
        id: 'myPdf',
        type: 'Form 8',
        receivedAt: '1/2/2017'
      };

      wrapper = shallow(<PdfUI
        doc={doc}
        file="test.pdf"
        id="pdf"
        pdfWorker="noworker"
        documentPathBase={DOCUMENT_PATH_BASE}
      />);
    });

    context('.render', () => {
      it('renders the outer div', () => {
        expect(wrapper.find('.cf-pdf-container')).to.have.length(1);
      });

      it('renders the title', () => {
        expect(wrapper.find('Button').find({ name: 'newTab' }).
          children().
          text()).to.eq(doc.type);
      });

      it('does not render the page number when pdf has not been rendered', () => {
        expect(wrapper.text()).to.not.include('Page 1 of 1');
      });

      it('renders the zoom buttons', () => {
        expect(wrapper.find({ name: 'zoomOut' })).to.have.length(1);
        expect(wrapper.find({ name: 'zoomIn' })).to.have.length(1);
      });

      context('when showDocumentsListNavigation is true', () => {
        it('renders the back to document list button', () => {
          expect(wrapper.find({ name: 'backToDocuments' })).to.have.length(0);

          wrapper.setProps({ showDocumentsListNavigation: true });
          expect(wrapper.find({ name: 'backToDocuments' })).to.have.length(1);
        });
      });
    });

    context('.onPageChange', () => {
      it('updates the state', () => {
        let currentPage = 2;
        let numPages = 4;

        wrapper.instance().onPageChange(currentPage, numPages);
        expect(wrapper.state('currentPage')).to.equal(currentPage);
        expect(wrapper.state('numPages')).to.equal(numPages);
      });

      it('updates the UI with the new page location', () => {
        let currentPage = 2;
        let numPages = 4;

        wrapper.setProps({ pdfsReadyToShow: { [doc.id]: true } });
        wrapper.instance().onPageChange(currentPage, numPages);
        expect(wrapper.text()).to.include(`Page ${currentPage} of ${numPages}`);
      });
    });

    context('.zoom', () => {
      it('sets the zoom state', () => {
        let delta = 0.5;
        let currentZoom = wrapper.state('scale');

        wrapper.instance().zoom(delta)();
        expect(wrapper.state('scale')).to.equal(currentZoom + delta);
      });
    });

    context('clicking', () => {
      // I'd like to use spies to make sure zoom is called
      // with the correct values instead of checking state
      // directly. But it proved to be too difficult to
      // spy on a closure generated within client code.
      context('zoomIn', () => {
        it('updates the scale by .3', () => {
          let delta = 0.3;
          let currentZoom = wrapper.state('scale');

          wrapper.find({ name: 'zoomIn' }).simulate('click');
          expect(wrapper.state('scale')).to.equal(currentZoom + delta);
        });
      });

      context('zoomOut', () => {
        it('updates the scale by -.3', () => {
          let delta = -0.3;
          let currentZoom = wrapper.state('scale');

          wrapper.find({ name: 'zoomOut' }).simulate('click');
          expect(wrapper.state('scale')).to.equal(currentZoom + delta);
        });
      });

      context('document name', () => {
        it('tries to open document in new tab', () => {
          let url = `${DOCUMENT_PATH_BASE}/${doc.id}?type=${doc.type}` +
            `&received_at=${doc.receivedAt}&filename=${doc.filename}`;
          let open = sinon.spy(window, 'open');

          wrapper.find('Button').find({ name: 'newTab' }).
            simulate('click');
          expect(open.withArgs(url, '_blank').calledOnce).to.be.true;
        });
      });

    });
  });
});

/* eslint-enable no-unused-expressions */
