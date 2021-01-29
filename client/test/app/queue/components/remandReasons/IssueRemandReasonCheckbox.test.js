import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { IssueRemandReasonCheckbox } from 'app/queue/components/remandReasons/IssueRemandReasonCheckbox';
import COPY from 'COPY';

describe('IssueRemandReasonCheckbox', () => {
  const onChange = jest.fn();
  const option = { id: 'lorem', label: 'Lorem Ipsum' };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('AMA', () => {
    it('renders correctly by default', () => {
      const { container } = render(
        <IssueRemandReasonCheckbox option={option} />
      );

      expect(container).toMatchSnapshot();

      expect(screen.getByText(option.label)).toBeInTheDocument();
    });

    it('hides AOJ choice until checked', async () => {
      const { container } = render(
        <IssueRemandReasonCheckbox option={option} />
      );

      expect(
        screen.queryByText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_BEFORE)
      ).not.toBeTruthy();
      expect(
        screen.queryByText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_AFTER)
      ).not.toBeTruthy();

      userEvent.click(screen.getByRole('checkbox'));

      expect(
        screen.queryByText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_BEFORE)
      ).toBeTruthy();
      expect(
        screen.queryByText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_AFTER)
      ).toBeTruthy();

      expect(container).toMatchSnapshot();
    });

    it('properly fires onChange', async () => {
      render(<IssueRemandReasonCheckbox option={option} onChange={onChange} />);

      userEvent.click(screen.getByRole('checkbox'));

      expect(onChange).toHaveBeenCalledTimes(1);
      expect(onChange).toHaveBeenLastCalledWith({
        code: option.id,
        checked: true,
        post_aoj: null,
      });

      userEvent.click(
        screen.getByLabelText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_BEFORE)
      );

      expect(onChange).toHaveBeenCalledTimes(2);
      expect(onChange).toHaveBeenLastCalledWith({
        code: option.id,
        checked: true,
        post_aoj: 'false',
      });

      userEvent.click(
        screen.getByLabelText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_AFTER)
      );

      expect(onChange).toHaveBeenCalledTimes(3);
      expect(onChange).toHaveBeenLastCalledWith({
        code: option.id,
        checked: true,
        post_aoj: 'true',
      });
    });
  });
});
