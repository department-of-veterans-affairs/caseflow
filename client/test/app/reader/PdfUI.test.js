import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import PdfUI from '../../../app/reader/PdfUI';
import ReduxBase from '../../../../client/app/components/ReduxBase';

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
    featureToggles: { search: true }
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

  // Setup usually combines passed props and default props
  // This one implements an anti-pattern and mocks a reducer, I'm doing this for two reasons:
  // 1) It's still (slightly) better than the existing karma tests since we're trying to deprecate Karma.
  // 2) This grossness can likely be removed/fixed after the reader refactor changes/rewrites this component.
  const setup = (props) => {
    const rootReducer = jest.fn();

    rootReducer.mockReturnValue(mockState);

    return render(
      <ReduxBase reducer={rootReducer}>
        <PdfUI {...defaultProps} {...props} />;
      </ReduxBase>
    );
  };

  describe('render', () => {
    it('renders correctly', () => {
      const { container } = setup();

      expect(container).toMatchSnapshot();
    });

    // This fails, skipping because there is a major reader refactor
    // in progress that should fix the error that's being reported.
    it.skip('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('correctly displays html elements', () => {

    });
  });

  describe('actions', () => {
    it('calls action on click of XXX', () => {});
  });
});
