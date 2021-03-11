import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import userEvent, { specialChars } from '@testing-library/user-event';
import { PdfUIPageNumInput } from '../../../app/reader/PdfUIPageNumInput';

describe('PdfUIPageNumInput', () => {
  const jumpToPage = jest.fn();

  const props = {
    jumpToPage,
    numPages: 20,
    docId: 42
  };

  const setupTestComponent = () => {
    return render(<PdfUIPageNumInput {...props} />);
  };

  beforeEach(() => {
    jumpToPage.mockClear();
  });

  it('renders properly', () => {
    const component = setupTestComponent(props);

    expect(component).toMatchSnapshot();
  });

  it('shows current page number', () => {
    setupTestComponent(props);

    expect(screen.getByLabelText('Page').value).toEqual('1');
  });

  describe('jump to page', () => {
    it('jumps to new page when different page number input', () => {
      setupTestComponent(props);
      const input = screen.getByLabelText('Page');

      userEvent.type(input, `${specialChars.backspace}3${specialChars.enter}`);

      expect(jumpToPage).toHaveBeenCalledTimes(1);
      expect(screen.getByLabelText('Page').value).toEqual('3');
    });

    it('parses non int input to int and jumps to that page', () => {
      setupTestComponent(props);
      const input = screen.getByLabelText('Page');

      userEvent.type(input, `${specialChars.backspace}2.5${specialChars.enter}`);

      expect(jumpToPage).toHaveBeenCalledTimes(1);
      expect(screen.getByLabelText('Page').value).toEqual('2');
    });

    it('does not jump to new page if input is greater than number of pages', () => {
      setupTestComponent(props);
      const input = screen.getByLabelText('Page');

      userEvent.type(input, `${specialChars.backspace}100${specialChars.enter}`);

      expect(jumpToPage).toHaveBeenCalledTimes(0);
    });
  });
});
