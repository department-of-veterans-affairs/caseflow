import React from 'react';
import { MemoryRouter } from 'react-router-dom';

import { mount } from 'enzyme';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

import {
  HearingTypeConversionForm,
} from 'app/hearings/components/HearingTypeConversionForm';
import { legacyAppealForTravelBoard } from 'test/data/appeals';
import { queueWrapper } from '../../../data/stores/queueStore';
import { HearingTypeConversion } from 'app/hearings/components/HearingTypeConversion';
import {
  HearingTypeConversionProvider,
} from 'app/hearings/contexts/HearingTypeConversionContext';
import { virtualAppeal, scheduleHearingTask } from 'test/data';
import ApiUtil from 'app/util/ApiUtil';

let patchSpy;

beforeEach(() => {
  patchSpy = jest.spyOn(ApiUtil, 'patch').
    mockImplementationOnce(() => new Promise((resolve) => resolve({ body: {} })));
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('HearingTypeConversion', () => {
  test('Matches snapshot with default props', () => {
    const hearingTypeConversion = mount(
      <HearingTypeConversionProvider>
        <HearingTypeConversion
          appeal={legacyAppealForTravelBoard}
          type="Virtual"
        />
      </HearingTypeConversionProvider>,
      {
        wrappingComponent: queueWrapper,
      }
    );

    expect(hearingTypeConversion.exists(HearingTypeConversionForm)).toBeTruthy();
    expect(hearingTypeConversion).toMatchSnapshot();
  });

  const renderHearingTypeConversionForm = (userIsVsoEmployee) => {
    return render(
      <HearingTypeConversionProvider initialAppeal={virtualAppeal}>
        <HearingTypeConversion
          appeal={virtualAppeal}
          task={scheduleHearingTask}
          type={virtualAppeal.type}
          userIsVsoEmployee={userIsVsoEmployee}
          history={{ push: jest.fn() }}
          showSuccessMessage={jest.fn()}
          showErrorMessage={jest.fn()}
        />
      </HearingTypeConversionProvider>
    );
  };

  describe('#submit payload', () => {
    test('Payload submitted by non-VSO employee meets expected format', () => {
      renderHearingTypeConversionForm(false);

      userEvent.click(screen.getByRole('button', { name: 'Convert Hearing To Virtual' }));

      let dataParam = patchSpy.mock.calls[0][1].data;

      expect(dataParam.task.business_payloads).toEqual({
        values: {
          changed_hearing_request_type: 'R',
          closest_regional_office: 'Somewhere, USA'
        }
      });
    });

    test('Payload submitted by VSO employee meets expected format', () => {
      renderHearingTypeConversionForm(true);

      const confirmEmailField = screen.getByRole('textbox', { name: 'Confirm Appellant Email Required' });

      // Fill out required form fields/checkboxes
      userEvent.type(confirmEmailField, 'susan@gmail.com');
      userEvent.click(screen.getByRole('checkbox', { name: 'Affirm Permission' }));
      userEvent.click(screen.getByRole('checkbox', { name: 'Affirm Access' }));

      // Submit the form
      userEvent.click(screen.getByRole('button', { name: 'Convert Hearing To Virtual' }));

      let dataParam = patchSpy.mock.calls[0][1].data;

      expect(dataParam.task.business_payloads).toEqual({
        values: {
          changed_hearing_request_type: 'R',
          closest_regional_office: 'Somewhere, USA',
          email_recipients: {
            appellant_tz: 'Africa/Nairobi',
            representative_tz: 'America/New_York',
            appellant_email: 'susan@gmail.com',
            representative_email: 'tom@brady.com'
          }
        }
      });
    });
  });
});
