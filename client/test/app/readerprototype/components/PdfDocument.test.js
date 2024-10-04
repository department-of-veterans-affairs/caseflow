import PdfDocument from 'app/readerprototype/components/PdfDocument';
import React from 'react';
import { act, render, waitFor } from '@testing-library/react';
import ApiUtil from 'app/util/ApiUtil';

const doc = {
  content_url: '/some/file/here'
};

describe('Handling metrics for a pdf document', () => {
  it('sends data when a document is fully loaded', async () => {
    jest.mock('app/util/ApiUtil', () => ({
      post: jest.fn(),
    }));

    const spy = jest.spyOn(ApiUtil, 'post');

    act(async () => {
      const { container } = render(<PdfDocument doc={doc} />);

      container.setAllPagesRendered = true;

      await waitFor(() => expect(spy).toHaveBeenCalledWith({}));
    });

  });

  it('sends data when a document is not fully loaded', async () => {
    jest.mock('app/util/ApiUtil', () => ({
      post: jest.fn(),
    }));

    const spy = jest.spyOn(ApiUtil, 'post');

    act(async () => {
      const { container } = render(<PdfDocument doc={doc} />);

      container.setAllPagesRendered = false;

      await waitFor(() => expect(spy).toHaveBeenCalledWith({}));
    });

  });
});
