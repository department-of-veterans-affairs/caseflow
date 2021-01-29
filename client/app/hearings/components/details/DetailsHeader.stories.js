import React, { useState, useContext } from 'react';
import { date, text, boolean, select } from '@storybook/addon-knobs';
import { addDecorator } from '@storybook/react';

import { DetailsHeader } from './DetailsHeader';
import { BrowserRouter } from 'react-router-dom';

export default {
  title: 'Hearings/Components/Hearing Details/DetailsHeader',
  component: DetailsHeader,
};

const Wrapper = ({ children }) => {
  return (
    <BrowserRouter>
      {children}
    </BrowserRouter>
  );
};

export const Normal = () => {
  return (
    <Wrapper>
      <DetailsHeader
        aod={boolean('Is Aod?', false, 'knobs')}
        disposition={text('Disposition', 'held', 'knobs')}
        docketName={text('Docket Name', 'hearing', 'knobs')}
        docketNumber={text('Docket Number', '1234567', 'knobs')}
        isVirtual={boolean('Is Virtual?', false, 'knobs')}
        hearingDayId={1}
        readableLocation={text('Location', 'Regional Office', 'knobs')}
        readableRequestType={select('Request Type', ['Central', 'Virtual', 'Video'], 'Video', 'knobs')}
        regionalOfficeName={text('Regional Office Name', 'Regional Office', 'knobs')}
        scheduledFor={date('Scheduled For', new Date(), 'knobs')}
        veteranFirstName={text('Veteran Last Name', 'Last', 'knobs')}
        veteranLastName={text('Veteran First Name', 'First', 'knobs')}
        veteranFileNumber={text('Veteran File Number', '12345678', 'knobs')}
      />
    </Wrapper>
  );
};
