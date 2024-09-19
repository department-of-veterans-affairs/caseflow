import React from 'react';
import { render } from '@testing-library/react';
import { ReaderFooter } from '../../../../app/readerprototype/components/ReaderFooter';
import { afterEach } from 'node:test';
// import userEvent from '@testing-library/user-event';

describe('ReaderFooter', () => {

  const defaultProps = {
    docId: 42,
    numPages: 20,
  };

  const setupTestComponent = (props = {}) => {
    return render(<ReaderFooter {...defaultProps} {...props} />);
  };

  it('renders properly', () => {
    const component = setupTestComponent();

    expect(component).toMatchSnapshot();
  });


});

describe('ReaderFooter', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should render with filtered docs count to indicate this is a filtered document list', () => {
    const { getByText } = render(
      <ReaderFooter documentList={['doc1', 'doc2']} filteredList={['doc1']} />
    );

    expect(getByText('Filtered Docs Count: 1')).toBeInTheDocument();
    // setupTestComponent();
    // const input = ;

    // userEvent.type(input, 'doc');
  });

  it('should not render with filtered docs count to indicate this is a filtered document list', () => {
    const { getByText } = render(

      <ReaderFooter documentList={['doc1', 'doc2']} filteredList={[]} />
    );

    expect(getByText(/Filtered Docs Count:/)).not.toBeInTheDocument();
    // setupTestComponent();
    // const input = ;

    // userEvent.type(input, 'doc');
  });

  it('indicate in the footer that it has been updated with the document in the list', () => {
    const { getByText } = render(
      <ReaderFooter documentList={['doc1', 'doc2']} filteredList={[]} />
    );

    expect(getByText('Footwe has been updated with the document list')).toBeInTheDocument();
    // setupTestComponent();
    // const input = ;

    // userEvent.type(input, 'doc');
  });

  it('does not indicate in the footer that it has been updated with the document in the list', () => {
    const { getByText } = render(
      <ReaderFooter documentList={[]} filteredList={[]} />
    );

    expect(getByText('Footer has not been updated wit the document List')).toBeInTheDocument();
    // setupTestComponent();
    // const input = ;

    // userEvent.type(input, 'doc');
  });
});

/*
Steps to Reproduce:
1. Go to DocumentList and apply filters.
Go to a documents and check the "Document x out of y" indicator
in the footer
2. Navigatge through the documents by clicking "Next/Previous"
buttons (or using the right/left arrow keys)

Expected Results:
1. The "Document x out of y" indicator in the footer should be
updated with the filtered docs count and there should be a filtered
icon (funnel) to indicate this is a filtered document list
2. The "Document x out of y" indicator in the footer should be
updated with the document in the list
*/

