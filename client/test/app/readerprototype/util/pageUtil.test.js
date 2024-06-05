import { render, waitFor } from '@testing-library/react';
import React from 'react';
import { renderPage } from '../../../../app/readerprototype/util//pageUtil';
// es5 build necessary for jest to work
import fs from 'fs';
import * as PDFJS from 'pdfjs-dist/es5/build/pdf';

describe('pageUtil', () => {
  const DummyComponent = () => {
    const setupPage = async () => {
      const raw = fs.readFileSync('test/fixtures/pdfs/Informal_Form9.pdf');
      const arrayBuffer = raw.buffer;

      const pdf = await PDFJS.getDocument({data: arrayBuffer}).promise;
      const page = await pdf.getPage(1);

      await renderPage(page);
    };

    setupPage();

    return (
      <div id="pdfContainer" />
    );
  };

  it('sets up the page to be rendered', async () => {
    const { getByText } = render(<DummyComponent />);

    await waitFor(
      () => expect(
        getByText('This is an informal form 9 statement. Jane Veteran would like a video hearing with the')
      ).toBeInTheDocument()
    );
  });
});
