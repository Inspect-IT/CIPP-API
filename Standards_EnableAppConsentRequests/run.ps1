param($tenant)

try {
    # Get current state
    $CurrentInfo = New-GraphGetRequest -uri 'https://graph.microsoft.com/beta/policies/adminConsentRequestPolicy' -tenantid $Tenant

    # Change state to enabled with default settings
    $CurrentInfo.isEnabled = 'true'
    $CurrentInfo.notifyReviewers = 'true'
    $CurrentInfo.remindersEnabled = 'true'
    $CurrentInfo.requestDurationInDays = 30

    # Currently GA role - TODO: Add role selection from standards
    $RolesToAdd = @('62e90394-69f5-4237-9190-012177145e10')

    $NewReviewers = foreach ($Role in $RolesToAdd) {
        @{
            query     = "/beta/roleManagement/directory/roleAssignments?`$filter=roleDefinitionId eq '$Role'"
            queryType = 'MicrosoftGraph'
            queryRoot = 'null'
        }
    }

    # Add existing reviewers
    $Reviewers = [System.Collections.Generic.List[object]]::new()
    foreach ($Reviewer in $CurrentInfo.reviewers) {
        $RoleFound = $false
        foreach ($Role in $RolesToAdd) {
            if ($Reviewer.query -match $RolesToAdd) {
                $RoleFound = $true
            }
        }
        if (!$RoleFound) {
            $Reviewers.add($Reviewer)
        }
    }

    # Add new reviewer roles
    foreach ($NewReviewer in $NewReviewers) {
        $Reviewers.add($NewReviewer)
    }

    # Update reviewer list
    $CurrentInfo.reviewers = @($Reviewers)
    $body = (ConvertTo-Json -Compress -Depth 10 -InputObject $CurrentInfo)

    New-GraphPostRequest -tenantid $tenant -Uri 'https://graph.microsoft.com/beta/policies/adminConsentRequestPolicy' -Type put -Body $body -ContentType 'application/json'
    Write-LogMessage -API 'Standards' -tenant $tenant -message 'Enabled App consent admin requests' -sev Info

} catch {
    Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to enable App consent admin requests. Error: $($_.exception.message)" -sev Error
}
