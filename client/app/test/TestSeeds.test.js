import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react';
import TestSeeds from './TestSeeds';
import ApiUtil from '../util/ApiUtil';

jest.mock('../util/ApiUtil');

describe('TestSeeds component', () => {
  it('handles seed runs correctly', async () => {
    const { getByText, getByLabelText } = render(<TestSeeds />);

    fireEvent.change(getByLabelText('Run Demo Aod Seeds'), { target: { value: 'aod' } });

    await waitFor(() => {
      expect(ApiUtil.post).toHaveBeenCalledWith(expect.anything());
      expect(getByText('Seeds running')).toBeInTheDocument();
    });
  });
});
