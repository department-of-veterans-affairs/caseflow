import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { IssueRemandReasonsForm } from 'app/queue/components/remandReasons/IssueRemandReasonsForm';
import COPY from 'COPY';

const issue = {
  id: 1,
  benefit_type: 'education',
  description: 'Lorem ipsum and whatnot',
  diagnostic_code: '503',
  disposition: 'remanded',
};

describe('IssueRemandReasonsForm', () => {
  const onChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('AMA', () => {
    it('renders correctly by default', () => {
      const { container } = render(
        <IssueRemandReasonsForm issue={issue} issueNumber={1} issueTotal={2} />
      );

      expect(container).toMatchSnapshot();

      expect(screen.getByText('Issue 1 of 2')).toBeInTheDocument();
      expect(
        screen.getByText(`Issue description: ${issue.description}`)
      ).toBeInTheDocument();
    });

    it('properly fires onChange', async () => {
      render(
        <IssueRemandReasonsForm
          issue={issue}
          issueNumber={1}
          issueTotal={2}
          onChange={onChange}
        />
      );

      userEvent.click(
        screen.getByRole('checkbox', { name: /issue-1-medical_opinions/ })
      );

      expect(onChange).toHaveBeenCalledTimes(1);
      expect(onChange).toHaveBeenLastCalledWith([
        {
          code: 'medical_opinions',
          checked: true,
          post_aoj: null,
        },
      ]);

      userEvent.click(
        screen.getByLabelText(COPY.AMA_REMAND_REASON_POST_AOJ_LABEL_BEFORE)
      );

      expect(onChange).toHaveBeenCalledTimes(2);
      expect(onChange).toHaveBeenLastCalledWith([
        {
          code: 'medical_opinions',
          checked: true,
          post_aoj: 'false',
        },
      ]);
    });
  });
});
