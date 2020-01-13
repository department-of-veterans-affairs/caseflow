import React from 'react';

import { action } from '@storybook/addon-actions';
import { withKnobs, text, boolean, select, object, array } from '@storybook/addon-knobs';

import Button from './Button';

const btnTypes = ['button', 'submit', 'reset'];

export default {
  title: 'Commons/Components/Button',
  component: Button,
  decorators: [withKnobs]
};

export const allOptions = () => (
  <Button
    id={text('ID', undefined, 'allOptions')}
    type={select('Type', btnTypes, 'button', 'allOptions')}
    onClick={action('clicked', 'allOptions')}
    name={text('Name', 'example', 'allOptions')}
    disabled={boolean('Disabled', false, 'allOptions')}
    linkStyling={boolean('Link Styling', false, 'allOptions')}
    loading={boolean('Loading', false, 'allOptions')}
    loadingText={text('Loading Text', undefined, 'allOptions')}
    willNeverBeLoading={boolean('Will Never Be Loading', false, 'allOptions')}
    ariaLabel={text('ARIA Label', undefined, 'allOptions')}
    classNames={array('Class Names', [], ' ', 'allOptions')}
    styling={object('Styling', {}, 'allOptions')}
  >
    {text('Contents', 'Sign Up', 'allOptions')}
  </Button>
);

export const primary = () => (
  <Button
    onClick={action('clicked', 'primary')}
    name={text('Name', 'example', 'primary')}
    disabled={boolean('Disabled', false, 'primary')}
  >
    {text('Contents', 'Sign Up', 'primary')}
  </Button>
);

export const secondary = () => (
  <Button
    onClick={action('clicked', 'secondary')}
    name={text('Name', 'example', 'secondary')}
    disabled={boolean('Disabled', false, 'secondary')}
    classNames={array('Class Names', ['usa-button-secondary'], ' ', 'secondary')}
  >
    {text('Contents', 'Sign Up', 'secondary')}
  </Button>
);

export const link = () => (
  <Button
    onClick={action('clicked', 'link')}
    name={text('Name', 'example', 'link')}
    disabled={boolean('Disabled', false, 'link')}
    linkStyling={boolean('Link Styling', true, 'link')}
  >
    {text('Contents', 'Sign Up', 'link')}
  </Button>
);

export const disabled = () => (
  <Button
    onClick={action('clicked', 'disabled')}
    name={text('Name', 'example', 'disabled')}
    disabled={boolean('Disabled', true, 'disabled')}
  >
    {text('Contents', 'Sign Up', 'disabled')}
  </Button>
);

export const loading = () => (
  <Button
    onClick={action('clicked', 'loading')}
    name={text('Name', 'example', 'loading')}
    disabled={boolean('Disabled', false, 'loading')}
    loading={boolean('Loading', true, 'loading')}
    loadingText={text('Loading Text', '', 'loading')}
  >
    {text('Contents', 'Sign Up', 'loading')}
  </Button>
);
