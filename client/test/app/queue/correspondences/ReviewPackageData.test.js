import React from 'react';
import { render, screen } from '@testing-library/react';
import ReviewPackageData from '../../../../app/queue/correspondence/review_package/ReviewPackageData';
import { reviewPackageDataResponse } from '../../../data/correspondence';
import ApiUtil from '../../../../app/util/ApiUtil';
jest.mock('../../../../app/util/ApiUtil');

const renderReviewPackageData = async () => {
  ApiUtil.get.mockResolvedValue(reviewPackageDataResponse);

  const props = {
    correspondenceId: reviewPackageDataResponse.body.correspondence.uuid
  };

  return render(<ReviewPackageData {...props} />);
};

describe('ReviewPackageData', () => {
  it('renders ReviewPackageData component', async () => {
    await renderReviewPackageData();
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

  it('renders Preview Document Section', async () => {
    await renderReviewPackageData();
    expect(screen.getByText('Document Type')).toBeInTheDocument();
    expect(screen.getByText('Action')).toBeInTheDocument();

    expect(screen.getByText('VA Form 10182 Notice of Disagreement')).toBeInTheDocument();
    expect(screen.getByText('Exam Request')).toBeInTheDocument();
  });
});
