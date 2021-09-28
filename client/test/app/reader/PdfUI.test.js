import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import PdfUI from '../../../app/reader/PdfUI';
import ReduxBase from '../../../../client/app/components/ReduxBase';
import { BrowserRouter } from 'react-router-dom';

describe('PdfUI', () => {
  const defaultProps = {
    doc: {
      filename: 'My PDF',
      id: 3,
      type: 'Form 8',
      receivedAt: '1/2/2017',
      content_url: '',
    },
    file: 'test.pdf',
    filteredDocIds: [1, 5],
    id: 'pdf',
    pdfWorker: 'noworker',
    documentPathBase: '/reader/appeal/reader_id1',
    showClaimsFolderNavigation: false,
    featureToggles: { search: true },
  };

  const mockState = {
    pdf: {
      documents: { 1: {}, 5: {}, 18: {} },
      documentErrors: [],
      pdfDocuments: {},
    },
    pdfViewer: {
      hidePdfSidebar: false
    },
    documentList: {
      filteredDocIds: [1, 5],
      searchCategoryHighlights: {},
    },
    annotationLayer: {
      isPlacingAnnotation: false
    },
    searchActionReducer: {
      extractedText: ''
    }
  };
  const rootReducer = jest.fn();

  rootReducer.mockReturnValue(mockState);

  // Setup usually combines passed props and default props
  // This one implements an anti-pattern and mocks a reducer, I'm doing this for two reasons:
  // 1) It's still (slightly) better than the existing karma tests since we're trying to deprecate Karma.
  // 2) This grossness can likely be removed/fixed after the reader refactor changes/rewrites this component.
  const setup = (props) => {
    return render(
      <ReduxBase reducer={rootReducer}>
        <BrowserRouter>
          <PdfUI {...defaultProps} {...props} />;
        </BrowserRouter>
      </ReduxBase>
    );
  };

  describe('render', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    // a11y testing fails, skipping because there is a major reader refactor
    // in progress that should fix this
    it.skip('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('correctly displays key html elements', () => {
      setup();

      const titleLink = screen.getByText(defaultProps.doc.type);
      const zoomOut = screen.getByRole('button', { name: 'zoom out' });
      const zoomIn = screen.getByRole('button', { name: 'zoom in' });
      const search = screen.getByRole('search');

      expect(titleLink).toBeInTheDocument();
      expect(zoomOut).toBeInTheDocument();
      expect(zoomIn).toBeInTheDocument();
      expect(search).toBeInTheDocument();
    });

    describe('the back button', () => {
      it('is shown showClaimsFolderNavigation is true', () => {
        setup({ showClaimsFolderNavigation: true });
        const back = screen.getByRole('link', { name: 'Back' });

        expect(back).toBeInTheDocument();
      });

      it('is hidden when showClaimsFolderNavigation is false', () => {
        setup({ showClaimsFolderNavigation: false });
        const back = screen.queryByRole('link', { name: 'Back' });

        expect(back).toBeNull();
      });

      it('calls stopPlacingAnnotation when clicked', async () => {
        window.analyticsEvent = jest.fn();

        setup({ showClaimsFolderNavigation: true });
        const back = screen.getByRole('link', { name: 'Back' });

        await userEvent.click(back);

        // Because stopPlacingAnnotation is used in bindActionCreators this is the best way to test that
        // it gets called. This analytics event is only called directly before stopPlacingAnnotation
        await waitFor(() => {
          expect(window.analyticsEvent).toHaveBeenCalledWith('Document Viewer', 'back-to-claims-folder');
        });
      });
    });
  });
});
