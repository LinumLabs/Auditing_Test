// Happy Path Test:
// Ensure that the function works correctly when a new company is registered.
// Check that the CompanyRegistered event is emitted.
// Verify that the isCompanyRegistered mapping is updated appropriately.
// Verify that the numberOfCompanies counter is incremented.

// Duplicate Registration Test:
// Test to confirm that attempting to register the same company (same msg.sender) again results in the appropriate error message.
// Ensure that the state of the contract remains unchanged when a duplicate registration is attempted.

// Empty _ipfsHash Test:
// Test with an empty string as the _ipfsHash parameter to ensure that the function handles this case correctly.

// Gas Consumption Test:
// Assess the gas consumption of the function, especially if gas efficiency is a concern in your application.
// Consider testing the function with a high number of registrations to see how gas costs scale.

// Event Data Test:
// Check the data emitted in the CompanyRegistered event to ensure that it reflects the expected values.

// Address Mapping Test:
// Verify that the companyAddresses mapping is updated correctly with the new company address.

//Overflow Test:
// Test the function with a very large number of registrations to ensure that the numberOfCompanies counter does not overflow.

// Edge Case Testing:
// Consider testing edge cases, such as registering companies with different edge values for parameters or in specific scenarios.

// Negative Testing:
// Attempt to call the function with incorrect parameters or in a state where registration should not be allowed. Ensure that appropriate error messages are triggered.

// Integration Testing:
// If there are other functions or contracts that interact with the registration process, conduct integration tests to ensure smooth interactions.