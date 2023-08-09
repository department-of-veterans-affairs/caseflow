import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import OrganizationUsers from 'app/queue/OrganizationUsers';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil');

describe('Conference Selection Visibility Feature Toggle', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });
  it('Finds component by Text (Webex and Pexip) when conferenceSelectionVisibility is false', async () => {
    const conferenceSelectionVisibilityValue = false;

    ApiUtil.get.mockResolvedValue({
      body: {
        organization_name: 'Hearing Admin',
        judge_team: false,
        dvc_team: false,
        organization_users: {
          data: [
            {
              id: '126',
              type: 'administered_user',
              attributes: {
                css_id: 'BVASORANGE',
                full_name: 'Felicia BuildAndEditHearingSchedule Orange',
                email: null,
                admin: false,
                dvc: null
              }
            },
            {
              id: '2000001601',
              type: 'administered_user',
              attributes: {
                css_id: 'AMBRISVACO',
                full_name: 'Gail Maggio V',
                email: 'juli@stroman-kertzmann.net',
                admin: true,
                dvc: null
              }
            },
          ],
        },
        membership_requests: [],
        isVhaOrg: false
      }
    });

    const { findAllByText } = render(
      <OrganizationUsers
        conferenceSelectionVisibility={conferenceSelectionVisibilityValue}
      />
    );
    const nestedTextWebex = await findAllByText('Webex');
    const nestedTextPexip = await findAllByText('Pexip');

    expect(nestedTextWebex[0]).toBeInTheDocument();
    expect(nestedTextPexip[0]).toBeInTheDocument();
  });

  it('Finds component by Text (Webex and Pexip) when conferenceSelectionVisibility is true', async () => {
    const conferenceSelectionVisibilityValue = true;

    ApiUtil.get.mockResolvedValue({
      body: {
        organization_name: 'Hearing Admin',
        judge_team: false,
        dvc_team: false,
        organization_users: {
          data: [
            {
              id: '126',
              type: 'administered_user',
              attributes: {
                css_id: 'BVASORANGE',
                full_name: 'Felicia BuildAndEditHearingSchedule Orange',
                email: null,
                admin: false,
                dvc: null,
              },
            },
            {
              id: '2000001601',
              type: 'administered_user',
              attributes: {
                css_id: 'AMBRISVACO',
                full_name: 'Gail Maggio V',
                email: 'juli@stroman-kertzmann.net',
                admin: true,
                dvc: null,
              },
            },
          ],
        },
        membership_requests: [],
        isVhaOrg: false,
      },
    });

    const { queryAllByText } = render(
      <OrganizationUsers
        conferenceSelectionVisibility={conferenceSelectionVisibilityValue}
      />
    );
    const nestedTextWebex = await queryAllByText('Webex');
    const nestedTextPexip = await queryAllByText('Pexip');

    expect(nestedTextWebex).toHaveLength(0);
    expect(nestedTextPexip).toHaveLength(0);
  });

  it('Component does not render when orginization_name is  ot Hearing Admin', async () => {
    const conferenceSelectionVisibilityValue = true;

    ApiUtil.get.mockResolvedValue({
      body: {
        organization_name: 'Hearing Management',
        judge_team: false,
        dvc_team: false,
        organization_users: {
          data: [
            {
              id: '126',
              type: 'administered_user',
              attributes: {
                css_id: 'BVASORANGE',
                full_name: 'Felicia BuildAndEditHearingSchedule Orange',
                email: null,
                admin: false,
                dvc: null,
              },
            },
            {
              id: '2000001601',
              type: 'administered_user',
              attributes: {
                css_id: 'AMBRISVACO',
                full_name: 'Gail Maggio V',
                email: 'juli@stroman-kertzmann.net',
                admin: true,
                dvc: null,
              },
            },
          ],
        },
        membership_requests: [],
        isVhaOrg: false,
      },
    });

    const { queryAllByText } = render(
      <OrganizationUsers
        conferenceSelectionVisibility={conferenceSelectionVisibilityValue}
      />
    );
    const nestedTextWebex = await queryAllByText('Webex');
    const nestedTextPexip = await queryAllByText('Pexip');

    expect(nestedTextWebex).toHaveLength(0);
    expect(nestedTextPexip).toHaveLength(0);

  });
});
