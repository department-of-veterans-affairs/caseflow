import React from 'react';
import { render } from '@testing-library/react';

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
      <CopyTextButton {...props} />
    );

    const button = utils.getByRole('button');

    return { ...utils, button };
  };

  describe('Button', () => {
    it('is enabled', async() => {
      const { button } = setup(defaults);

      expect(button).toBeEnabled();
    });
    it('is disabled', async() => {
      const text = 'some text';
      const label = 'Label';
      const { button } = setup({ text, label });

      expect(button).toBeDisabled();
    });
  });

  describe('aria-label', () => {
    it('passes a11y testing', async () => {
      const { container } = setup(defaults);

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('sets aria-label from ariaLabel prop if available', async () => {
      const ariaLabel = '';
      const { button } = setup({ ariaLabel });

      expect(button.getAttribute('aria-label')).toBe(ariaLabel);
    });

    it('falls back to label prop and text prop if no ariaLabel prop', async () => {
      const ariaLabel = '';
      const text = 'the text';
      const label = 'the label';
      const { button } = setup({ ariaLabel, text, label });

      expect(button.getAttribute('aria-label')).toBe('');
    });
  });
});
