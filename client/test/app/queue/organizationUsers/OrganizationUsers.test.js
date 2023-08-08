import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import OrganizationUsers from 'app/queue/OrganizationUsers';
import ApiUtil from 'client/app/util/ApiUtil.js';

jest.mock('/client/app/util/ApiUtil');

describe('Conference Selection Visibility Feature Toggle', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });
  it('renders the nested component when conferenceSelectionVisibility is true', async () => {
    const conferenceSelectionVisibilityValue = true;

    ApiUtil.get.mockResolvedValue({
      body: {
        organizationName: 'Hearing Admin',

      },
    });

    render(
      <OrganizationUsers
        conferenceSelectionVisibility= {conferenceSelectionVisibilityValue}
      />
    );

    const nestedText = await screen.findByText('Remove from team:');
    screen.debug();
    expect(nestedText).toBeInTheDocument();
  });

  // it("does not render the nested component for other conditions", () => {
  //   render(
  //     <OrganizationUsers
  //       organizationName="Hearing Management"
  //       conferenceSelectionVisibility= {true}
  //     />
  //   );

  //   const nestedTextQuery = screen.queryByText("Pexip");
  //   expect(nestedTextQuery).not.toBeInTheDocument();

  //   render(
  //     <OrganizationUsers
  //       organizationName="Hearing Admin"
  //       conferenceSelectionVisibility={false}
  //     />
  //   );

  //   const nestedTextQuery2 = screen.queryByText("Pexip");
  //   expect(nestedTextQuery2).not.toBeInTheDocument();
  // });
});
