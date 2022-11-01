import React from 'react';
import { render } from '@testing-library/react';
import {
    BrowserRouter as Router,
} from 'react-router-dom';
import { Provider } from 'react-redux';
import { createStore } from 'redux';
import { axe } from 'jest-axe';
import { act } from 'react-dom/test-utils';
import NotificationTable from '../../../app/queue/components/NotificationTable';

// jest.mock('../../../app/queue/components/NotificationTable', () => ({
//     fetchNotifications: jest.fn(() => [])
// }));


const setup = () => {
    const props = {
        appealId: 'e1bdff31-4268-4fd4-a157-ebbd48013d91'
    };

    return render(
        <NotificationTable {...props} />
    )
}

describe('NotificationTable', () => {
    it('renders event column correctly', () => {
        const { container } = setup();
        const header = container.querySelector('#header-eventType').innerHTML;

        expect(header).toBe('Event');
    });

    it('renders notification type column correctly', () => {
        const { container } = setup();
        const header = container.querySelector('#header-notificationType').innerHTML;

        expect(header).toBe('Notification Type');
    })

    it('renders notification date column correctly', () => {
        const { container } = setup();
        const header = container.querySelector('#header-eventDate').innerHTML;

        expect(header).toBe('Notification Date');
    })

    it('renders recipient information column correctly', () => {
        const { container } = setup();
        const header = container.querySelector('#header-recipientInformation').innerHTML;

        expect(header).toBe('Recipient Information');
    })

    it('renders status column correctly', () => {
        const { container } = setup();
        const header = container.querySelector('#header-status').innerHTML;

        expect(header).toBe('Status');
    })
})