import React from 'react';
import { render, screen } from '@testing-library/react';
import { DocumentCategoryIcons } from '../../../app/reader/DocumentCategoryIcons';

describe('DocumentCategoryIcons', () => {
  it('renders no icons when the doc is not in any categories', () => {
    render(<DocumentCategoryIcons doc={{}} />);
    const listItems = screen.queryByLabelText('document categories');

    expect(listItems).not.toBeInTheDocument();
  });

  it('renders an icon when the doc is in category_procedural', () => {
    const doc = {
      category_procedural: true // eslint-disable-line camelcase
    };

    render(<DocumentCategoryIcons doc={doc} />);

    const listItems = screen.queryByLabelText('document categories');

    expect(listItems).toBeInTheDocument();

    expect(listItems.firstChild).toHaveAttribute('aria-label', expect.stringContaining('Procedural'));
  });

  it('renders an icon when the doc is in category_other', () => {
    const doc = {
      category_other: true // eslint-disable-line camelcase
    };

    render(<DocumentCategoryIcons doc={doc} />);

    const listItems = screen.queryByLabelText('document categories');

    expect(listItems).toBeInTheDocument();

    expect(listItems.firstChild).toHaveAttribute('aria-label', expect.stringContaining('Other Evidence'));
  });

  it('renders an icon when the doc is in category_medical', () => {
    const doc = {
      category_medical: true // eslint-disable-line camelcase
    };

    render(<DocumentCategoryIcons doc={doc} />);

    const listItems = screen.queryByLabelText('document categories');

    expect(listItems).toBeInTheDocument();

    expect(listItems.firstChild).toHaveAttribute('aria-label', expect.stringContaining('Medical'));
  });

  it('renders four icons when the doc is in all categories', () => {
    const doc = {
      category_procedural: true, // eslint-disable-line camelcase
      category_medical: true, // eslint-disable-line camelcase
      category_other: true, // eslint-disable-line camelcase
      category_case_summary: true // eslint-disable-line camelcase
    };

    render(<DocumentCategoryIcons doc={doc} />);

    const listItems = screen.queryByLabelText('document categories');

    expect(listItems).toBeInTheDocument();

    expect(listItems.childNodes[0]).toHaveAttribute('aria-label', expect.stringContaining('Procedural'));
    expect(listItems.childNodes[1]).toHaveAttribute('aria-label', expect.stringContaining('Medical'));
    expect(listItems.childNodes[2]).toHaveAttribute('aria-label', expect.stringContaining('Other Evidence'));
    expect(listItems.childNodes[3]).toHaveAttribute('aria-label', expect.stringContaining('Case Summary'));

  });
});
