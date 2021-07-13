$testExecutionId = New-Guid
$filesFolder = "./testdata_batch"
$startDate = Get-Date

$filesCount = Read-Host "How many of each file type? For exmaple, if you enter 10, you'll get 10 txt, 10 jpg and 10 mp4"

Write-Host "Test Execution: $testExecutionId"

for ($num = 0 ; $num -lt $filesCount ; $num++)
{ 
    # Create text file with unique contents and place it in the test folder
    $uniqueContents = ('This file was created by the test file generator on {0}. TestExecutionId {1}. File number {2}' -f $startDate, $testExecutionId, $num)
    #$textFilePath = $filesFolder + "/$testExecutionId_text_$num.txt"
    $textFilePath = ('{0}/{1}_text_{2}.txt' -f $filesFolder, $testExecutionId, $num)
    $uniqueContents | New-Item -Path $textFilePath -ItemType File -Force

    # Create image file with unique contents and place it in the test folder
    $imageFilePath = ('{0}/{1}_image_{2}.jpg' -f $filesFolder, $testExecutionId, $num)
    $imageTempMediaUrl = ('https://via.placeholder.com/1600x400.jpg&text={0}-{1}' -f $testExecutionId, $num)
    Invoke-WebRequest $imageTempMediaUrl -OutFile $imageFilePath -SkipCertificateCheck

    # Create video file with unique contents and place it in the test folder
    $videoFilePath = ('{0}/{1}_video_{2}.jpg' -f $filesFolder, $testExecutionId, $num)
    $videoTempMediaUrl = ('https://via.placeholder.com/1600x400.jpg&text=vid{0}-{1}' -f $testExecutionId, $num)
    Invoke-WebRequest $videoTempMediaUrl -OutFile $videoFilePath -SkipCertificateCheck
}

