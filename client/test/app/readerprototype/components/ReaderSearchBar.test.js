import { render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import React, { useState } from 'react';
import RenderSearchBar from '../../../../app/readerprototype/components/ReaderSearchBar';

describe.skip('finds results', () => {
  // mock scrolling since it isn't included in jsdom
  window.HTMLElement.prototype.scrollIntoView = jest.fn;

  const DummyComponent = () => {
    const [openSearch, setOpenSearch] = useState(false);

    return (
      <>
        <button onClick={() => setOpenSearch(true)}>Open</button>
        {openSearch && <RenderSearchBar />}

        <div id="pdfContainer">
          <p>1DoCuMent TiTle</p>
          <span id="second-example">This 2document has 3document-like stuff happening</span>
          4Document is an album by R.E.M.
        </div>
        <div>This part of the document should be ignored, since we only want to search within the pdfContainer</div>
      </>
    );
  };

  it('finds text', async () => {
    const { container, getByPlaceholderText, getByText } = render(<DummyComponent />);

    userEvent.click(getByText('Open'));

    const input = getByPlaceholderText('Type to search...');

    expect(container.querySelector('mark')).not.toBeInTheDocument();

    userEvent.click(input);
    userEvent.type(input, 'doc');

    // newer versions of testing-library/dom support querying 'marks' by aria role
    // but our version doesn't support it yet
    expect(container.querySelectorAll('mark')).toHaveLength(4);
    expect(container.querySelectorAll('mark.highlighted')).toHaveLength(1);
    expect(container.querySelector('p > mark.highlighted')).toBeInTheDocument();

    userEvent.click(getByText('Next Match'));
    expect(container.querySelectorAll('mark.highlighted')).toHaveLength(1);
    expect(container.querySelector('p > mark.highlighted')).not.toBeInTheDocument();
    expect(container.querySelector('#second-example > mark.highlighted')).toBeInTheDocument();

    userEvent.click(getByText('Previous Match'));
    expect(container.querySelectorAll('mark.highlighted')).toHaveLength(1);
    expect(container.querySelector('#second-example > mark.highlighted')).not.toBeInTheDocument();
    expect(container.querySelector('p > mark.highlighted')).toBeInTheDocument();

    userEvent.type(container, '{enter}');
    expect(container.querySelectorAll('mark.highlighted')).toHaveLength(1);
    expect(container.querySelector('p > mark.highlighted')).not.toBeInTheDocument();
    expect(container.querySelector('#second-example > mark.highlighted')).toBeInTheDocument();

    // newer version of user-event needed to test the [meta][shift]+g behavior
  });
});
