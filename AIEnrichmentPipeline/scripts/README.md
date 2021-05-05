# Scripts

We have a set of tests written using Pester that can be invoked via PowerShell. All test script files are located under the `\scripts\` folder of this repo and are split into two categories:

- Infrastructure (Tests related to the setup/config of infrastructure components. Example: is the location of a storage account what we expect)
- Integration (Tests related to the functionality of infrastructure components. Example: when a messages is put on the service bus does the logic app fire and give the expected result)

## TL;DR Getting Started

Before running any scripts, you MUST [configure your environment first](#Credentials)

To run your tests:

```bash
pwsh -c 'Invoke-psake make.ps1 test-deployment'
```

To run only a specific test:

```bash
pwsh -c 'Invoke-psake make.ps1 integration-tests -parameters @{"testFilePath"="[your test file name here].tests.ps1";}'
```

> Please note: you can substitute `integration_tests` with `infra_tests` above depending on where the test resides.

## Infrastructure Tests

These tests check that the components/resources deployed via Terraform match the configuration we expect. For example, they check that we have a storage account deployed for Azure Media Services and that the Azure Media Services account is configured to point to the correct storage account.

the purpose of these tests is to ensure that we have not misconfigured something within our Terraform and introduced a regression.

To run the infrastructure tests execute: `pwsh -c 'Invoke-psake make.ps1 infra-tests'`

## Integration Tests

These tests check that our system components are behaving as we expect. These assume that Terraform has deployed and configured some logical processing unit (a logic app for example) and are used to test that given X as input, we get the expected value Y as output. These tests are used to ensure that we haven't broken something within the logic of our services/applications.

To run the infrastructure tests execute: `pwsh -c 'Invoke-psake make.ps1 integration-tests'`

## Credentials and .env

Some tests require credentials to be set when running locally.

The `make.ps1` uses [`Set-PSEnv` to load the variables from a `.env` file](https://github.com/rajivharris/Set-PsEnv) in the project root. To take advantage of this copy `example.env` to `.env` and configure the values you require then you can run `pwsh -c 'Invoke-psake make.ps1 integration-tests'` as normal. The `.env` file is ignore from `git` so the values can't be accidentally committed to the repo.

Alternatively you can set these by running `export VAR_NAME_NERE=VALUE` before running `pwsh -c 'Invoke-psake make.ps1 integration-tests'`

In addition to the configuration above, to run the tests [you may need to connect your Azure Powershell cmdlets](https://docs.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount?view=azps-5.3.0) to the currently authenticated account by running: `Connect-AzAccount -DeviceAuth`.

## Running a specific test

There may be a need to run a specific test rather than all the tests we currently have written. This is easily achieved through the use of the following command: `pwsh -c 'Invoke-psake make.ps1 infra-tests -parameters @{"testFilePath"="videoindexer.tests.ps1";}'`

> Note: the use of the `-parameters` to specify the name of the file you wish to run within the correct test folder. The parameter must always be named `testFilePath` and then the name of the file to test. More info about this feature of `psake` [can be found here](https://psake.readthedocs.io/en/latest/pass-parameters/)

The same can be done for the integration tests: `pwsh -c 'Invoke-psake make.ps1 integration-tests -parameters @{"testFilePath"="appinsights.tests.ps1";}'`

## Testing Parallel Test execution locally

In the build server each test file is executed in parallel to speed things up. You can enable this mode as follows locally to test out issue:

```
TEST_LOGS=true RUN_TESTS_PARALLEL=true NO_BUILD=true pwsh -c 'Invoke-psake ./make.ps1 integration-tests'
```

Setting `TEST_LOGS` means that during execution you can see the up-to-date output of a test in `./testlogs/{test file name}.log`

## Generating synthetic content to test with

You may require large volumes of data to test the system at scale. Files can be synthetically generated using the [testfile_generator tool](./scripts/testfile_generator).