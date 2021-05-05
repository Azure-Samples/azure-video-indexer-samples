# Test File Generator Tool
Generates files to be used to large scale/bulk upload testing.

## Usage
`pwsh -c 'testfilegenerator.ps1`

The tool will prompt you for how many files you need to be created.

The resulting files will be in the `/scripts/testfile_generator/testdata_batch` folder. 

These can then be uploaded to the `input` storage account on Azure which will initiate the pipeline.