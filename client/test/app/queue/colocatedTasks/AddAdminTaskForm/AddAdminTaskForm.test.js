import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import { AddAdminTaskForm } from 'app/queue/colocatedTasks/AddAdminTaskForm/AddAdminTaskForm';
import { FormProvider, useForm } from 'react-hook-form';

// eslint-disable-next-line react/prop-types
const Wrapper = ({ children }) => {
  const methods = useForm();

  return <FormProvider {...methods}>{children}</FormProvider>;
};

describe('AddAdminTaskForm', () => {
  const onRemove = jest.fn();

  const baseName = 'newTasks[0]';
  const item = { type: '', instructions: '' };

  const defaults = { baseName, item, onRemove };

  const setup = (props = {}) =>
    render(<AddAdminTaskForm {...defaults} {...props} />, {
      wrapper: Wrapper,
    });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('fires onRemove', async () => {
    setup();
    expect(onRemove).not.toHaveBeenCalled();

    await userEvent.click(
      screen.getByRole('button', { name: /remove this action/i })
    );
    expect(onRemove).toHaveBeenCalled();
  });

  it('focuses the first element when mounted', async () => {
    setup();

    expect(screen.getByRole('textbox', { name: /select the type of task/i })).toHaveFocus();
  });
});
