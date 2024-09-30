import { render } from '@testing-library/react';
import Page from 'app/readerprototype/components/Page';
import { def, get } from 'bdd-lazy-var/getter';
import fs from 'fs';
import { getDocument } from 'pdfjs-dist/es5/build/pdf';
import React from 'react';

window.IntersectionObserver = jest.fn(() => ({
  observe: jest.fn(),
  disconnect: jest.fn()
}));

def(
  'render',
  () => async () => {
    const pageData = async () => {
      const raw = fs.readFileSync('test/fixtures/pdfs/Informal_Form9.pdf');
      const arrayBuffer = raw.buffer;

      const pdf = await getDocument({ data: arrayBuffer }).promise;

      return await pdf.getPage(1);
    };

    return render(
      <Page page={await pageData()} scale={100} />
    );
  }
);

it('renders', async () => {
  const { container } = await get.render();

  expect(container).toMatchSnapshot();
});
