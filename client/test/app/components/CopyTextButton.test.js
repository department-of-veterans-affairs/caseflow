import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { axe } from 'jest-axe';

import CopyTextButton from 'app/components/CopyTextButton';

const defaults = {
  text: 'default text',
  textToCopy: 'default textToCopy',
  label: 'default label',
  ariaLabel: '',
};

describe('CopyTextButton', () => {
  const setup = (props) => {

    const utils = render(
      <CopyTextButton {...defaults} {...props} />
    );

    const button = utils.getByRole('button');

    return { ...utils, button };
  };

  describe('aria-label', () => {
    it('passes a11y testing', async () => {
      const { container } = setup();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('sets aria-label from ariaLabel prop if available', async () => {
      const ariaLabel = 'the aria label';
      const { button } = setup({ ariaLabel });

      expect(button.getAttribute('aria-label')).toBe(ariaLabel);
    });

    it('falls back to label prop and text prop if no ariaLabel prop', async () => {
      const ariaLabel = '';
      const text = 'the text';
      const label = 'the label';
      const { button } = setup({ ariaLabel, text, label });

      expect(button.getAttribute('aria-label')).toBe(`Copy ${label} ${text}`);
    });
  });
});
