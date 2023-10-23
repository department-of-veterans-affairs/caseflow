import React from 'react';
import { css } from 'glamor';
import { connect } from 'react-redux';

import { MemoryRouter } from 'react-router';
// import { ActiveLiver } from './ActiveLiver';
import AdminTabs from './AdminTabs';

import { Tabs } from 'app/components/tabs/Tabs';
import { Tab } from 'app/components/tabs/Tab';

import InteractableLever from './InteractableLever';
import { levers } from 'test/data/adminCaseDistributionLevers';
import Alert from 'app/components/Alert';
import UserAlerts from 'app/components/UserAlerts';
import {VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE} from  '../../../../COPY';

// const judgeTeam = createJudgeTeam(1)[0];

const RouterDecorator = (Story) => (
  <MemoryRouter initialEntries={['/']}>
    <Story />
  </MemoryRouter>
);

const leverTop = css({
  '& p': {margin: '10px 0', fontSize: '14px'}
});

const leverContainer = css({
  width: '100%',
  border: '1px solid #e4e2e0',
  borderRadius : '4px',
  marginTop: '20px',
  display: 'inline-block',
  '& h4' : {margin:'0', background: '#e4e2e0', padding: '10px 20px'},
  '& strong' : {fontSize: '14px'}
});

const leverContent = css({
  width: '100%',
  padding: '20px',
  paddingBottom: '0',
  boxSizing: 'border-box',
  '& p' : {marginTop: '0', marginBottom: '15px', fontSize: '14px'}
});

const leverHead = css({
  width: '100%',
  borderBottom: '1px solid #e4e2e0',
  display: 'inline-block',
  paddingBottom: '15px'
});

const leverLeft = css({
  width: '70%',
  display: 'inline-block',
  marginRight: '30px'
});

const leverRight = css({
  width: '25%',
  display: 'inline-block'
});

// const leverBottom = css({
//   width: '100%',
//   padding: '20px',
//   boxSizing: 'border-box',
//   display: 'inline-block'
// });

// const floatRight = css({
//   float: 'right',
//   margin: '0'
// });


export default {
  title: 'Admin/Caseflow Distribution/AdminTabs',
  component: AdminTabs,
  decorators: [RouterDecorator],
  args: {
    showDistributionToggles: false,
  },
  argTypes: {
    onUpdate: { action: 'onUpdate' }
  }
};

export const tabs = (args) => (

  <Tabs {...args}>
    <Tab title="Case Distribution" value="1">
      <div className={leverTop}>
        <strong>Caseflow Distribution content</strong>
        <p>Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.</p>
      </div>
      {/* <Alert
          type="info"
          message="Lorem Ipsum is simply dummy text of the printing and typesetting industry."
      /> */}
      <div className={leverContainer}>
        <h4>Active Data Elements</h4>
        <div className={leverContent}>
          <p>Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.</p>
          <p><strong> <sup>*</sup> Lorem Ipsum is simply dummy text of the printing and typesetting industry.</strong></p>
          <div className={leverHead}>
            <div className={leverLeft}><strong>Data Elements</strong></div>
            <div className={leverRight}><strong>Value</strong></div>
          </div>
          { levers.map((lever) => {
            return lever ? (
              <InteractableLever key={lever.item} lever={lever} />
            ) : null;
          })}
          {/* <div className={leverBottom}>
            <a href='#' >Cancel</a>
            <button className={floatRight}>Save Changes</button>
          </div> */}
        </div>
      </div>
    </Tab>
    <Tab title="Veteran Extract" value="2">
      Veteran Extract content
    </Tab>
  </Tabs>
);
