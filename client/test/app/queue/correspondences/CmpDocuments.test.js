import React from 'react';
import { render, screen } from '@testing-library/react';
import CmpDocuments from '../../../../app/queue/correspondence/ReviewPackage/CmpDocuments';
import { correspondenceDocumentsData } from '../../../data/correspondence';

const renderCmpDocuments = () => {
  return render(<CmpDocuments documents={correspondenceDocumentsData} />);
};

describe('CmpDocuments', () => {
  it('renders Preview Document Section', () => {
    renderCmpDocuments();
    expect(screen.getByText('Document Type')).toBeInTheDocument();
    expect(screen.getByText('Action')).toBeInTheDocument();

    expect(screen.getByText('VA Form 10182 Notice of Disagreement')).toBeInTheDocument();
    expect(screen.getByText('Exam Request')).toBeInTheDocument();
  });
});
