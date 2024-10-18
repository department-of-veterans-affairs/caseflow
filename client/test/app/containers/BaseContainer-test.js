import React from 'react';
import { render } from '@testing-library/react';
import BaseContainer from '../../../app/containers/BaseContainer';

describe('BaseContainer', () => {
  beforeEach(() => {
    render(<BaseContainer page="TestPage" otherProp="foo" />);
  });

  describe('sub-page', () => {
    it('renders', () => {
      // Query for the element with the class 'sub-page' using container and querySelector
      const subPageElement = document.querySelector('.sub-page');
      expect(subPageElement).toBeInTheDocument();
    });
  });
});
