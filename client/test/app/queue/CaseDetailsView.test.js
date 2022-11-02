import React from 'react';
import { render, screen } from '@testing-library/react';
import  CaseDetailsView  from "../../../app/queue/CaseDetailsView";
import { StoreValue } from './CaseDetailsViewData';
import { queueWrapper as Wrapper } from 'test/data/stores/queueStore';
import { amaAppeal,legacyAppeal } from '../../data/appeals';
import COPY from '../../../COPY';

const defaultProps = {userCanScheduleVirtualHearings:true,
userCanAccessReader:true,
userCanEditUnrecognizedPOA:true,
vsoVirtualOptIn:true,
}
const renderCaseDetailsView = (hasNotifications, appealData) => {
  const storevalues = {queue:{appeals:[{...appealData, hasPOA:true, hasNotifications}]}}
const props = {...defaultProps,appealId:appealData.id}
  render(
    <Wrapper {...storevalues} >
    <CaseDetailsView {...props} />
  </Wrapper>
  )
}

describe('NotificationsLink', () => {
  describe('When there are notifications', () => {
    it('link appears with ama appeal', () => {
      renderCaseDetailsView(true,amaAppeal)

      expect(screen.getByText(COPY.VIEW_NOTIFICATION_LINK)).toBeTruthy()

    })
  
  })
  describe('When there are\'not notifications', () => {
  
  })
})