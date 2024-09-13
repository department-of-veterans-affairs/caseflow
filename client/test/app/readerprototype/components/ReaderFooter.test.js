import React from 'react';
import { render } from '@testing-library/react';
import { ReaderFooter } from '../../../../app/readerprototype/components/ReaderFooter';

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
