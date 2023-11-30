import React from 'react';
import * as redux from 'react-redux';
import { render, screen } from '@testing-library/react';
import ReviewPackageData from '../../../../app/queue/correspondence/review_package/ReviewPackageData';
import { correspondenceData, packageDocumentTypeData } from '../../../data/correspondence';
jest.mock('../../../../app/queue/correspondence/modals/editModal');

const renderReviewPackageData = () => {
  return render(
    <ReviewPackageData correspondence={correspondenceData} packageDocumentType={packageDocumentTypeData} />
  );
};

describe('ReviewPackageData', () => {
  const useSelectorMock = jest.spyOn(redux, 'useSelector');

  it('renders ReviewPackageData component', () => {
    useSelectorMock.mockReturnValueOnce(correspondenceData);
    useSelectorMock.mockReturnValueOnce(packageDocumentTypeData);
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
