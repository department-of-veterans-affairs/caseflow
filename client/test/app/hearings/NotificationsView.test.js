import React from 'react';
import { render } from '@testing-library/react';
// import { render, screen } from '@testing-library/react';
import NotificationsView from '../../../app/queue/NotificationsView'
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { axe } from 'jest-axe';





describe('NotificationsTest', () => {

  const defaults = {};

   const setup = (props) =>
   <Provider>
    render(<NotificationsView {...defaults} {...props} />);

  it('renders correctly', () => {
    const { container } = setup();

     expect(container).toMatchSnapshot()
  });

  it('passes a11y testing', async () => {
     const { container } = setup();

   const results = await axe(container);

     expect(results).toHaveNoViolations();
  });


</Provider>
});