[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "GitHub File Uploader"
$form.Width = 500
$form.Height = 350
$form.StartPosition = "CenterScreen"

# Repository URL Label and TextBox
$labelRepo = New-Object System.Windows.Forms.Label
$labelRepo.Text = "GitHub Repository URL:"
$labelRepo.Location = New-Object System.Drawing.Point(10, 20)
$labelRepo.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($labelRepo)

$textboxRepo = New-Object System.Windows.Forms.TextBox
$textboxRepo.Location = New-Object System.Drawing.Point(10, 45)
$textboxRepo.Size = New-Object System.Drawing.Size(460, 30)
$textboxRepo.Text = "https://github.com/username/repository.git"
$form.Controls.Add($textboxRepo)

# File Path Label and TextBox
$labelFile = New-Object System.Windows.Forms.Label
$labelFile.Text = "File to Upload:"
$labelFile.Location = New-Object System.Drawing.Point(10, 90)
$labelFile.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($labelFile)

$textboxFile = New-Object System.Windows.Forms.TextBox
$textboxFile.Location = New-Object System.Drawing.Point(10, 115)
$textboxFile.Size = New-Object System.Drawing.Size(360, 30)
$textboxFile.ReadOnly = $true
$form.Controls.Add($textboxFile)

# Browse Button
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse"
$buttonBrowse.Location = New-Object System.Drawing.Point(375, 115)
$buttonBrowse.Size = New-Object System.Drawing.Size(95, 30)
$buttonBrowse.Add_Click({
    $openFile = New-Object System.Windows.Forms.OpenFileDialog
    $openFile.Filter = "All files (*.*)|*.*"
    $openFile.ShowDialog() | Out-Null
    $textboxFile.Text = $openFile.FileName
})
$form.Controls.Add($buttonBrowse)

# Commit Message Label and TextBox
$labelMsg = New-Object System.Windows.Forms.Label
$labelMsg.Text = "Commit Message:"
$labelMsg.Location = New-Object System.Drawing.Point(10, 160)
$labelMsg.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($labelMsg)

$textboxMsg = New-Object System.Windows.Forms.TextBox
$textboxMsg.Location = New-Object System.Drawing.Point(10, 185)
$textboxMsg.Size = New-Object System.Drawing.Size(460, 50)
$textboxMsg.Multiline = $true
$textboxMsg.Text = "Upload file via GitUploader"
$form.Controls.Add($textboxMsg)

# Status Label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Text = "Status: Ready"
$labelStatus.Location = New-Object System.Drawing.Point(10, 245)
$labelStatus.Size = New-Object System.Drawing.Size(460, 20)
$form.Controls.Add($labelStatus)

# Upload Button
$buttonUpload = New-Object System.Windows.Forms.Button
$buttonUpload.Text = "Upload to GitHub"
$buttonUpload.Location = New-Object System.Drawing.Point(180, 270)
$buttonUpload.Size = New-Object System.Drawing.Size(140, 40)
$buttonUpload.Add_Click({
    $repo = $textboxRepo.Text
    $file = $textboxFile.Text
    $msg = $textboxMsg.Text

    if (-not $repo -or -not $file) {
        [System.Windows.Forms.MessageBox]::Show("Please enter repository URL and select a file.", "Error")
        return
    }

    if (-not (Test-Path $file)) {
        [System.Windows.Forms.MessageBox]::Show("File does not exist.", "Error")
        return
    }

    $labelStatus.Text = "Status: Uploading..."
    $form.Refresh()

    try {
        $tempDir = "$env:TEMP\git_upload_$(Get-Random)"
        New-Item -ItemType Directory -Path $tempDir | Out-Null

        Push-Location $tempDir

        # Clone or init repo
        $labelStatus.Text = "Status: Cloning repository..."
        $form.Refresh()
        git clone $repo . 2>&1 | Out-Null

        # Copy file
        $fileName = Split-Path $file -Leaf
        Copy-Item $file -Destination $fileName -Force

        # Git add and commit
        $labelStatus.Text = "Status: Committing changes..."
        $form.Refresh()
        git add $fileName 2>&1 | Out-Null
        git commit -m $msg 2>&1 | Out-Null

        # Push
        $labelStatus.Text = "Status: Pushing to GitHub..."
        $form.Refresh()
        git push 2>&1 | Out-Null

        Pop-Location
        Remove-Item $tempDir -Recurse -Force

        $labelStatus.Text = "Status: Successfully uploaded!"
        [System.Windows.Forms.MessageBox]::Show("File uploaded successfully to GitHub!", "Success")
    }
    catch {
        $labelStatus.Text = "Status: Error occurred"
        [System.Windows.Forms.MessageBox]::Show("Error: $_", "Upload Failed")
    }
})
$form.Controls.Add($buttonUpload)

$form.ShowDialog()
