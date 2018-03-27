import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import sinon from 'sinon';

import { PdfUI } from '../../../app/reader/PdfUI';

const DOCUMENT_PATH_BASE = '/reader/appeal/reader_id1';

/* eslint-disable no-unused-expressions */
describe('PdfUI', () => {
  context('shallow create PdfUI', () => {
    let wrapper;
    let doc;

    beforeEach(() => {
      doc = {
        filename: 'My PDF',
        id: 3,
        type: 'Form 8',
        receivedAt: '1/2/2017'
      };

      wrapper = shallow(<PdfUI
        doc={doc}
        file="test.pdf"
        filteredDocIds={[3]}
        id="pdf"
        pdfWorker="noworker"
        documentPathBase={DOCUMENT_PATH_BASE}
        showClaimsFolderNavigation={false}
        featureToggles={{ search: true }}
      />);
    });

    context('.render', () => {
      it('renders the outer div', () => {
        expect(wrapper.find('.cf-pdf-container')).to.have.length(1);
      });

      it('renders the title as a link', () => {
        expect(wrapper.find('Link').find({ name: 'newTab' }).
          children().
          text()).to.eq(`${doc.type}<ExternalLink />`);
        expect(wrapper.find('Link').find({ name: 'newTab' }).
          first().
          props().target).to.eq('_blank');
      });

      it('does not render the page number when pdf has not been rendered', () => {
        expect(wrapper.text()).to.not.include('Page 1 of 1');
        expect(wrapper.text()).to.include('Loading document');
      });

      it('renders the zoom buttons', () => {
        expect(wrapper.find({ name: 'zoomOut' })).to.have.length(1);
        expect(wrapper.find({ name: 'zoomIn' })).to.have.length(1);
      });

      it('renders the search button', () => {
        expect(wrapper.find({ name: 'search' })).to.have.length(1);
      });

      context('when showClaimsFolderNavigation is true', () => {
        it('renders the back button that directs to claims folder', () => {
          expect(wrapper.find({ name: 'backToClaimsFolder' })).to.have.length(0);

          wrapper.setProps({ showClaimsFolderNavigation: true });
          expect(wrapper.find({ name: 'backToClaimsFolder' })).to.have.length(1);
        });
      });
    });

    context('.onPageChange', () => {
      it('updates the state', () => {
        let currentPage = 2;
        let fitToScreenZoom = 3;

        wrapper.instance().onPageChange(currentPage, fitToScreenZoom);
        expect(wrapper.state('currentPage')).to.equal(currentPage);
        expect(wrapper.state('fitToScreenZoom')).to.equal(fitToScreenZoom);
      });
    });

    context('clicking', () => {
      context('backToClaimsFolder', () => {
        it('calls the stopPlacingAnnotation props', () => {
          const mockStopPlacingAnnotationClick = sinon.spy();

          wrapper.setProps({
            showClaimsFolderNavigation: true,
            stopPlacingAnnotation: mockStopPlacingAnnotationClick
          });
          wrapper.find({ name: 'backToClaimsFolder' }).simulate('click');

          expect(mockStopPlacingAnnotationClick.calledOnce).to.be.true;
        });
      });
    });
  });
});

/* eslint-enable no-unused-expressions */
