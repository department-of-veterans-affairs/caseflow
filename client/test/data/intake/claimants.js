const sharedClaimantInfo = {
  address1: '123 Main St',
  address2: 'Apt 1',
  city: 'San Francisco',
  state: 'CA',
  country: 'USA',
  zip: '94123',
  phoneNumber: '555-123-4567',
};

export const individualClaimant = {
  partyType: 'individual',
  firstName: 'Jane',
  middleName: 'McClaimant',
  lastName: 'Doe',
  ...sharedClaimantInfo,
};

export const organizationClaimant = {
  partyType: 'organization',
  organization: 'Organization of Vet Helpers',
  ...sharedClaimantInfo,
};

// There is a possible case involving the redux store where the claimant object can have leftover information
// from a previous submission. This is used to test for that specific case.
export const leftoverSubmissionInformationClaimant = {
  partyType: 'organization',
  organization: 'Organization of Vet Helpers',
  firstName: 'Jane',
  middleName: 'McClaimant',
  ...sharedClaimantInfo
};

const sharedPoaInfo = {
  address1: '321 Main St',
  address2: 'Suite 5',
  city: 'Washington',
  state: 'DC',
  country: 'USA',
  zip: '20001',
  phoneNumber: '555-321-4567',
};

export const individualPoa = {
  partyType: 'individual',
  firstName: 'Paul',
  middleName: 'Ern',
  lastName: "O'Attorney",
  ...sharedPoaInfo,
};
