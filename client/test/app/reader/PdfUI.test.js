import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';

import PdfUI from '../../../app/reader/PdfUI';
import ReduxBase from '../../../../client/app/components/ReduxBase';
import rootReducer from '../../../../client/app/reader/reducers';
import { onReceiveDocs } from '../../../../client/app/reader/Documents/DocumentsActions';

describe('PdfUI', () => {
  const defaultProps = {
    doc: {
      filename: 'My PDF',
      id: 3,
      type: 'Form 8',
      receivedAt: '1/2/2017'
    },
    file: 'test.pdf',
    filteredDocIds: [1, 5],
    id: 'pdf',
    pdfWorker: 'noworker',
    documentPathBase: '/reader/appeal/reader_id1',
    showClaimsFolderNavigation: false,
    featureToggles: { search: true }
  };

  /*
    This is a component that's connected to the reader store, so it's proving complex
    to simply get it to render. The approach the karma tests used is to 'shallow' render
    it, but that's not really available (nor a good idea) in jest/redux testing.

    I've spent ~2 hours on this and while I'm learning a lot, I'm going to table this for now
    because there's a full reader refactor in the works
    https://github.com/department-of-veterans-affairs/caseflow/pull/15456

    I'm not sure on the timeline for that refactor, but it's probably worth putting off this
    test writing until after it merges? Or at least waiting a bit.
  */
  const setup = (props) => {
    const documents = { 1: {}, 5: {}, 18: {} };
    const vacolsId = '123456';

    return render(
      <ReduxBase reducer={rootReducer}>
        {onReceiveDocs(documents, vacolsId)}
        <PdfUI {...defaultProps} {...props} />;
      </ReduxBase>
    );
  };

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
