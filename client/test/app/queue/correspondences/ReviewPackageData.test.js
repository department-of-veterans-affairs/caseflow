import React from 'react';
import { render, screen } from '@testing-library/react';
import ReviewPackageData from '../../../../app/queue/correspondence/review_package/ReviewPackageData';
import { correspondenceData, packageDocumentTypeData } from '../../../data/correspondence';

const renderReviewPackageData = () => {
  /* eslint-disable max-len */
  return render(<ReviewPackageData correspondence={correspondenceData} packageDocumentType={packageDocumentTypeData} />);
};

describe('ReviewPackageData', () => {
  it('renders ReviewPackageData component', () => {
    renderReviewPackageData();
    expect(screen.getByText('Portal Entry Date')).toBeInTheDocument();
    expect(screen.getByText('Source Type')).toBeInTheDocument();
    expect(screen.getByText('Package Document Type')).toBeInTheDocument();
    expect(screen.getByText('CM Packet Number')).toBeInTheDocument();
    expect(screen.getByText('CMP Queue Name')).toBeInTheDocument();
    expect(screen.getByText('VA DOR')).toBeInTheDocument();

    expect(screen.getByText('11/16/2023')).toBeInTheDocument();
    expect(screen.getByText('Mail')).toBeInTheDocument();
    expect(screen.getByText('10182')).toBeInTheDocument();
    expect(screen.getByText('5555555555')).toBeInTheDocument();
    expect(screen.getByText('BVA Intake')).toBeInTheDocument();
    expect(screen.getByText('11/15/2023')).toBeInTheDocument();
  });
});
