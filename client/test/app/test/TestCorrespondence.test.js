import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import ApiUtil from 'app/util/ApiUtil';
import COPY from '../../../COPY';
import TestCorrespondence from 'app/test/TestCorrespondence';

// Mock the components used in TestCorrespondence
jest.mock('app/components/Button', () => ({ onClick, name }) => (
  <button onClick={onClick}>{name}</button>
));

jest.mock('app/components/TextareaField', () => ({ onChange, value }) => (
  <textarea value={value} onChange={(event) => onChange(event.target.value)} />
));

jest.mock('app/components/NumberField', () => ({ onChange, value }) => (
  <input type="number" value={value} onChange={(event) => onChange(event.target.value)} />
));

jest.mock('app/components/Alert', () => ({ type, title, message }) => (
  <div className={`alert ${type}`}>
    <h2>{title}</h2>
    <p>{message}</p>
  </div>
));

// Mock the ApiUtil.post method.
jest.spyOn(ApiUtil, 'post').mockImplementation(() => Promise.resolve({
  body: {
    invalid_file_numbers: '001',
    valid_file_nums: '002',
    correspondence_size: 5
  }
}));

describe('TestCorrespondence', () => {
  const props = {
    userDisplayName: 'Test User',
    dropdownUrls: [],
    applicationUrls: []
  };

  it('renders the component', () => {
    render(<TestCorrespondence {...props} />);
    expect(screen.getByText(COPY.CORRESPONDENCE_ADMIN.HEADER)).toBeInTheDocument();
  });

  it('handles veteran file numbers input', () => {
    render(<TestCorrespondence {...props} />);
    const textarea = screen.getByRole('textbox');

    fireEvent.change(textarea, { target: { value: '123,456,789' } });
    expect(textarea.value).toBe('123,456,789');
  });

  it('truncates file numbers if more than 10 are entered', () => {
    render(<TestCorrespondence {...props} />);
    const textarea = screen.getByRole('textbox');

    fireEvent.change(textarea, { target: { value: '1,2,3,4,5,6,7,8,9,10,11' } });
    expect(textarea.value).toBe('1,2,3,4,5,6,7,8,9,10');
  });

  it('handles correspondence count input', () => {
    render(<TestCorrespondence {...props} />);
    const numberField = screen.getByRole('spinbutton');

    fireEvent.change(numberField, { target: { value: '5' } });
    expect(numberField.value).toBe('5');
  });

  it('displays success and warning alerts on form submission', async () => {
    render(<TestCorrespondence {...props} />);
    const button = screen.getByRole('button', { name: /Generate correspondence/i });

    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(COPY.CORRESPONDENCE_ADMIN.SUCCESS.TITLE)).toBeInTheDocument();
      expect(screen.getByText(COPY.CORRESPONDENCE_ADMIN.INVALID_ERROR.TITLE)).toBeInTheDocument();
    });
  });

  it('displays the correct success message', async () => {
    render(<TestCorrespondence {...props} />);
    const button = screen.getByRole('button', { name: /Generate correspondence/i });

    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(/5 correspondence documents generated for: 002/i)).toBeInTheDocument();
    });
  });

  it('displays the correct invalid file numbers message', async () => {
    render(<TestCorrespondence {...props} />);
    const button = screen.getByRole('button', { name: /Generate correspondence/i });

    fireEvent.click(button);

    await waitFor(() => {
      expect(screen.getByText(/The following file numbers are invalid: 001/i)).toBeInTheDocument();
    });
  });
});
